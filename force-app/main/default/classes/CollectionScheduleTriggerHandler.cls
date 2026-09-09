public class CollectionScheduleTriggerHandler {

	private static Boolean isCloneInsertion = false; // Prevent recursive processing when clones are INSERTed

	public void handleTrigger(List<Schedule__c> newList, Map<Id, Schedule__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when BEFORE_INSERT {
				if (!isCloneInsertion) {
					processInsert(newList);
				}
			}
			when BEFORE_UPDATE {
				processUpdate(newList, oldMap);
			}
			when BEFORE_DELETE {
				processDelete(oldMap.values());
			}
			when AFTER_INSERT, AFTER_UPDATE {
				insertScheduleHistory(newList, oldMap);
			}
		}
	}

	private void processInsert(List<Schedule__c> newList) {
		Map<String, CollectionAggregator__c> mapAggregator = new Map<String, CollectionAggregator__c>();
		List<Schedule__c> clonedSchedules = new List<Schedule__c>();

		for (Schedule__c schedule : newList) {
			// Initialize Aggregator
			String aggregatorKey = generateAggregatorKey(schedule);
			CollectionAggregator__c aggregator = mapAggregator.get(aggregatorKey);
			if (aggregator == null) {
				aggregator = newCollectionAggregator(schedule, aggregatorKey);
				mapAggregator.put(aggregatorKey, aggregator);
			}

			// Set collection time for all days of week on Aggregator
			List<String> collectionDays = schedule.Days__c.split(';');
			setTimeOnDay(aggregator, collectionDays, schedule.Time__c);

			// Clone schedule for each day of week
			clonedSchedules.addAll(clone(schedule, collectionDays, aggregatorKey));

			// Doing this after clones are created, to avoid the 1st day being enabled in all clones
			setCollectionDay(schedule, collectionDays[0], aggregatorKey);
		}

		UPSERT mapAggregator.values() CollectionAggregator__c.Fields.Extkey__c;  // Changed to allOrNone=true

		// Assign Aggregator to each schedule
		List<Schedule__c> allSchedules = new List<Schedule__c>(newList);
		allSchedules.addAll(clonedSchedules);
		for (Schedule__c schedule : allSchedules) {
			schedule.CollectionAggregator__c = mapAggregator.get(generateAggregatorKey(schedule)).Id;
		}

		if (hasDuplicates(allSchedules)) {
			applyError(newList, Label.MsgDuplicateCollectionSchedule);
			return;
		}

		if (!clonedSchedules.isEmpty()) {
			isCloneInsertion = true;
			try {
				INSERT clonedSchedules;
			} catch (DmlException e) {
				applyError(newList, e.getDmlMessage(0));
			}
		}
	}

	private void insertScheduleHistory(List<Schedule__c> newList, Map<Id, Schedule__c> oldMap) {
		Set<Id> existingScheduleHistory = new Set<Id>();
		for (ScheduleAdvanceInvoiceHistory__c scheduleHistory : [SELECT Schedule__c FROM ScheduleAdvanceInvoiceHistory__c WHERE Schedule__c IN :newList AND CreatedDate = TODAY]) {
			existingScheduleHistory.add(scheduleHistory.Schedule__c);
		}

		List<ScheduleAdvanceInvoiceHistory__c> scheduleHistory = new List<ScheduleAdvanceInvoiceHistory__c>();
        List<Schedule__c> scheduleList = [SELECT Id, Location__c, Collection_Quantity__c, Start_Date__c, End_Date__c, Suspension_Start_Date__c, Reactivation_Start_Date__c, Is_bin_collection__c, Location__r.IsLive__c, Location__r.Parent.IsBinCollectionAdvanceInvoiced__c, Fortnightly__c FROM Schedule__c WHERE Id IN :newList]; 
		for (Schedule__c schedule : scheduleList) {
			if (!schedule.Location__r.Parent.IsBinCollectionAdvanceInvoiced__c || !schedule.Is_bin_collection__c || !schedule.Location__r.IsLive__c || existingScheduleHistory.contains(schedule.Id)) {
				continue;
			}

			Schedule__c oldSchedule = oldMap?.get(schedule.Id);
			if (oldSchedule == null) {
				scheduleHistory.add(new ScheduleAdvanceInvoiceHistory__c(Schedule__c = schedule.Id, Location__c = schedule.Location__c, IsNew__c = true));
			} else if (schedule.Collection_Quantity__c != oldSchedule.Collection_Quantity__c || schedule.Fortnightly__c != oldSchedule.Fortnightly__c
				|| schedule.Start_Date__c != oldSchedule.Start_Date__c || schedule.End_Date__c != oldSchedule.End_Date__c 
				|| schedule.Suspension_Start_Date__c != oldSchedule.Suspension_Start_Date__c || schedule.Reactivation_Start_Date__c != oldSchedule.Reactivation_Start_Date__c) {

				scheduleHistory.add(new ScheduleAdvanceInvoiceHistory__c(Schedule__c = oldSchedule.Id, Location__c = oldSchedule.Location__c, Quantity__c = oldSchedule.Collection_Quantity__c, IsFortnightly__c = oldSchedule.Fortnightly__c, 
					StartDate__c = oldSchedule.Start_Date__c, EndDate__c = oldSchedule.End_Date__c, SuspensionStartDate__c = oldSchedule.Suspension_Start_Date__c, ReactivationStartDate__c = oldSchedule.Reactivation_Start_Date__c));
			}
		}
		INSERT scheduleHistory;
	}

	private void processUpdate(List<Schedule__c> updatedList, Map<Id, Schedule__c> oldMap) {
		Map<Object, CollectionAggregator__c> mapAggregator = getAggregatorsByKey(oldMap.values());
		Map<Object, CollectionAggregator__c> aggregatorsToUpsert = new Map<Object, CollectionAggregator__c>();
		List<Schedule__c> schedulesToUpdateAggregator = new List<Schedule__c>();

		for (Schedule__c schedule : updatedList) {
			Schedule__c oldSchedule = oldMap.get(schedule.Id);
			String aggregatorKey = generateAggregatorKey(schedule);
			String aggregatorKeyOld = generateAggregatorKey(oldSchedule);
			if (aggregatorKey == aggregatorKeyOld) {    // Assumption is 'Day change' on a Schedule is not allowed
				continue;
			}

			// Update unique code due to change in key
			setUniqueCode(schedule, aggregatorKey);

			// Initialize Aggregator
			CollectionAggregator__c aggregator = mapAggregator.get(aggregatorKey);
			if (aggregator == null) {
				aggregator = newCollectionAggregator(schedule, aggregatorKey);
				mapAggregator.put(aggregatorKey, aggregator);
			}
			schedulesToUpdateAggregator.add(schedule);

			// Set collection time for day of week on new Aggregator
			setTimeOnDay(aggregator, schedule.Days__c, schedule.Time__c);
			aggregatorsToUpsert.put(aggregatorKey, aggregator);

			// Clear collection time for day of week on current Aggregator
			CollectionAggregator__c aggregatorOld = mapAggregator.get(aggregatorKeyOld);
			clearTimeOnDay(aggregatorOld, schedule.Days__c);
			aggregatorsToUpsert.put(aggregatorKeyOld, aggregatorOld);
		}

		if (hasDuplicates(schedulesToUpdateAggregator)) {
			applyError(schedulesToUpdateAggregator, Label.MsgDuplicateCollectionSchedule);
			return;
		}		

		if (aggregatorsToUpsert.isEmpty()) {
			return;
		}

		// Identify empty Aggregators that are to be deleted
		List<CollectionAggregator__c> aggregatorsToDelete = identifyAggregatorsToDelete(aggregatorsToUpsert);

		UPSERT aggregatorsToUpsert.values() CollectionAggregator__c.Fields.Extkey__c;    // Changed to allOrNone=true

		if (!aggregatorsToDelete.isEmpty()) {
			DELETE aggregatorsToDelete;
		}

		// Assign Aggregator to each schedule
		for (Schedule__c schedule : schedulesToUpdateAggregator) {
			schedule.CollectionAggregator__c = aggregatorsToUpsert.get(generateAggregatorKey(schedule)).Id;
		}
	}

	private void processDelete(List<Schedule__c> deletedList) {
		Map<Object, CollectionAggregator__c> aggregatorsToUpdate = getAggregatorsById(deletedList);

		// Clear collection time for day of week on Aggregator
		for (Schedule__c schedule : deletedList) {
			clearTimeOnDay(aggregatorsToUpdate.get(schedule.CollectionAggregator__c), schedule.Days__c);
		}

		// Identify empty Aggregators that are to be deleted
		List<CollectionAggregator__c> aggregatorsToDelete = identifyAggregatorsToDelete(aggregatorsToUpdate);

		if (!aggregatorsToUpdate.isEmpty()) {
			UPDATE aggregatorsToUpdate.values();
		}
		if (!aggregatorsToDelete.isEmpty()) {
			DELETE aggregatorsToDelete;
		}
	}

	private String generateAggregatorKey(Schedule__c schedule) {
		return schedule.Location__c + '-' + schedule.Supplier_Product__c + '-' + schedule.Collection_quantity__c.intValue() + '-' + schedule.Time__c;
	}

	private CollectionAggregator__c newCollectionAggregator(Schedule__c schedule, String aggregatorKey) {
		return new CollectionAggregator__c(Location__c=schedule.Location__c, Supplier_Product__c=schedule.Supplier_Product__c,
											Quantity__c=schedule.Collection_quantity__c.intValue(), Extkey__c=aggregatorKey);
	}

	private void setTimeOnDay(CollectionAggregator__c aggregator, List<String> collectionDays, String collectionTime) {
		for (String day : collectionDays) {
			setTimeOnDay(aggregator, day, collectionTime);
		}
	}

	private void setTimeOnDay(CollectionAggregator__c aggregator, String dayOfWeek, String collectionTime) {
		aggregator.put(dayOfWeek + '__c', collectionTime);
	}

	private void clearTimeOnDay(CollectionAggregator__c aggregator, String dayOfWeek) {
		if (aggregator != null && String.isNotBlank(dayOfWeek)) {
			setTimeOnDay(aggregator, dayOfWeek, '');
		}
	}

	private void setCollectionDay(Schedule__c schedule, String dayOfWeek, String aggregatorKey) {
		schedule.Days__c = dayOfWeek;
		schedule.put(dayOfWeek + '_Collection__c', true);   // Jira 1905 - New update to new fields created by Ruth, so the driver app users can validate how many schedules there are per Account
		setUniqueCode(schedule, aggregatorKey);             // Changed to set on cloned schedules also
	}

	private void setUniqueCode(Schedule__c schedule, String aggregatorKey) {
		schedule.UniqueCode__c = aggregatorKey + '-' + schedule.Days__c;
	}

	private List<Schedule__c> clone(Schedule__c schedule, List<String> collectionDays, String aggregatorKey) {
		List<Schedule__c> clonedSchedules = new List<Schedule__c>();
		if (collectionDays.size() < 2) {
			return clonedSchedules;
		}

		for (Integer i=1; i<collectionDays.size(); i++) {
			Schedule__c clonedDay = schedule.clone(false, true, true, false);   // Changed to preserveReadonlyTimestamps=true
			setCollectionDay(clonedDay, collectionDays[i], aggregatorKey);
			clonedSchedules.add(clonedDay);
		}
		return clonedSchedules;
	}

	private Map<Object, CollectionAggregator__c> getAggregatorsById(List<Schedule__c> schedules) {
		Set<Id> aggregatorIds = new Set<Id>();
		for (Schedule__c schedule : schedules) {
			aggregatorIds.add(schedule.CollectionAggregator__c);
		}

		return new Map<Object, CollectionAggregator__c>([SELECT Extkey__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c
													FROM CollectionAggregator__c WHERE Id IN :aggregatorIds]);
	}

	private Map<Object, CollectionAggregator__c> getAggregatorsByKey(List<Schedule__c> schedules) {
		Map<Object, CollectionAggregator__c> mapAggregator = new Map<Object, CollectionAggregator__c>();
		for (CollectionAggregator__c aggregator : getAggregatorsById(schedules).values()) {
			mapAggregator.put(aggregator.Extkey__c, aggregator);
		}
		return mapAggregator;
	}

	private List<CollectionAggregator__c> identifyAggregatorsToDelete(Map<Object, CollectionAggregator__c> aggregators) {
		List<CollectionAggregator__c> aggregatorsToDelete = new List<CollectionAggregator__c>();
		for (Object mapKey : aggregators.keySet()) {
			CollectionAggregator__c aggregator = aggregators.get(mapKey);
			if (!hasCollectionTime(aggregator)) {
				aggregatorsToDelete.add(aggregator);
				aggregators.remove(mapKey);
			}
		}
		return aggregatorsToDelete;
	}

	private Boolean hasCollectionTime(CollectionAggregator__c aggregator) {
		return String.isNotBlank(aggregator.Monday__c) || String.isNotBlank(aggregator.Tuesday__c) || String.isNotBlank(aggregator.Wednesday__c) || String.isNotBlank(aggregator.Thursday__c) ||
			String.isNotBlank(aggregator.Friday__c) || String.isNotBlank(aggregator.Saturday__c) || String.isNotBlank(aggregator.Sunday__c);
	}

	private Boolean hasDuplicates(List<Schedule__c> schedules) {
		Set<String> uniqueCodes = new Set<String>();
		for (Schedule__c schedule : schedules) {
			uniqueCodes.add(schedule.UniqueCode__c);
		}

		if (uniqueCodes.size() != schedules.size()) {
			return true;
		}

		return [SELECT COUNT() FROM Schedule__c WHERE UniqueCode__c IN :uniqueCodes] > 0;
	}

	private void applyError(List<Schedule__c> schedules, String errorMessage) {
		for (Schedule__c schedule : schedules) {
			schedule.addError(errorMessage);
		}
	}
}