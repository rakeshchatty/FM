public abstract without sharing class BusinessCentralEventHandler {

	private static final String FIELD_SET_NAME = 'BusinessCentral';
	private static final String FIELD_FORCE_SEND = 'BusinessCentralSendForcefully__c';

	private Boolean isLive;
	private Map<Id, sObject> eventRecords;
	protected Set<String> monitoredFields = new Set<String>();
	private List<BusinessCentralSendRequest__c> requestsToQueue = new List<BusinessCentralSendRequest__c>();

	protected abstract Map<Id, sObject> fetchRecords(Set<String> recordIds);
	protected abstract Boolean isSkipEvent(EventBus.ChangeEventHeader eventHeader, sObject sObj);
	protected abstract Boolean isSkipRecord(sObject sObj);
	protected abstract Boolean isRecordEligible(sObject sObj);
	protected abstract List<BusinessCentralSendRequest__c> createQueueRequests(Set<String> recordIds, List<String> changedFields);
	protected abstract String getkey(BusinessCentralSendRequest__c requestToQueue);

	protected BusinessCentralEventHandler(Schema.sObjectType sObjectType) {
		loadMonitoredFields(sObjectType);
	}

	public void handleTrigger(List<sObject> newList, Map<Id, sObject> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				queryEventRecords(newList);
				queueEligibleRecord(newList);
			}
		}
	}

	protected sObject getRecord(String recordId) {
		return eventRecords.get(recordId);
	}

	protected Boolean isChangedFieldsInMonitoredFields(EventBus.ChangeEventHeader eventHeader) {
		Set<String> monitoredFieldsClone = new Set<String>(monitoredFields);
		monitoredFieldsClone.retainAll(eventHeader.getChangedFields());
		return !monitoredFieldsClone.isEmpty();
	}

	protected virtual void loadMonitoredFields(Schema.sObjectType sObjectType) {
		Schema.FieldSet fieldSet = sObjectType.getDescribe().fieldSets.getMap().get(FIELD_SET_NAME);
		for (Schema.FieldSetMember field : fieldSet.getFields()) {
			monitoredFields.add(field.getFieldPath());
		}
	}

	private void queueEligibleRecord(List<sObject> newList) {
		for (sObject event : newList) {
			filterEligibleRecords((EventBus.ChangeEventHeader)event.get('ChangeEventHeader'));
		}

		dedupeQueueRequests();
		if (requestsToQueue.isEmpty()) {
			return;
		}

		INSERT requestsToQueue;
	}

	private void filterEligibleRecords(EventBus.ChangeEventHeader eventHeader) {
		Set<String> filteredRecordIds = new Set<String>();

		List<String> recordIds = eventHeader.getRecordIds();
		if (isForceSend(eventHeader)) {
			filteredRecordIds.addAll(recordIds);
		} else {
			if (isSkipEvent(eventHeader, eventRecords.get(recordIds[0]))) {	// Any one record can be used, as all records have the same change in an event
				return;
			}
			for (String recordId : recordIds) {
				if (isSkipRecord(eventRecords.get(recordId))) {	// Check each record for both changes and unchanged values
					continue;
				}
				filteredRecordIds.add(recordId);
			}
		}

		Set<String> recordIdsToQueue = new Set<String>();
		for (String recordId : filteredRecordIds) {
			if (isRecordEligible(eventRecords.get(recordId))) {	// Check each record for mimimum eligibility, even if force-send
				recordIdsToQueue.add(recordId);
			}
		}

		requestsToQueue.addAll(createQueueRequests(recordIdsToQueue, eventHeader.getChangedFields()));
	}

	private void dedupeQueueRequests() {
		Map<String, BusinessCentralSendRequest__c> uniqueRequests = new Map<String, BusinessCentralSendRequest__c>();
		for (BusinessCentralSendRequest__c requestToQueue : requestsToQueue) {
			uniqueRequests.put(getkey(requestToQueue), requestToQueue);
		}

		requestsToQueue = uniqueRequests.values();
	}

	private void queryEventRecords(List<sObject> newList) {
		Set<String> recordIds = new Set<String>();
		for (sObject event : newList) {
			recordIds.addAll(((EventBus.ChangeEventHeader)event.get('ChangeEventHeader')).getRecordIds());
		}

		eventRecords = fetchRecords(recordIds);
	}

	private Boolean isForceSend(EventBus.ChangeEventHeader eventHeader) {
		return eventHeader.getChangedFields().contains(FIELD_FORCE_SEND);
	}
}