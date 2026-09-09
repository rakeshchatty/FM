public class DispatchCreationBatch implements Database.Batchable<sObject>, Database.Stateful {

	private final DateTime NOW = System.now();
	private final String TODAY_DATE = NOW.format('dd/MM/yyyy');
	private final Id FIRST_MILE_SUPPLIER_ID = [SELECT Id FROM Suppliers__c WHERE Name = 'First Mile Ltd' LIMIT 1].Id;
	private final CollectionServiceTimeSetting__c SERVICE_TIME = CollectionServiceTimeSetting__c.getOrgDefaults();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Name,' +
				' (SELECT Name, CreatedById, Is_bin_collection__c, Is_Internal_Collection__c, Start_Date__c, End_Date__c, Collection_Quantity__c, Discount_Type__c, EarliestArrival__c, LatestArrival__c,' +
				' Location__c, Location__r.ParentId, Location__r.Parent.Account_Manager__c, Location__r.Partnership__c, List_Price__c, Enqix_Price__c, Supplier__c, Supplier_Product__c, Supplier_Product__r.Product__c' +
				' FROM Collections__r WHERE Collection_Active__c = true AND Collection_today__c = true' +
				' ORDER BY Location__c)' +
			' FROM Round__c WHERE IsActiveToday__c = true ORDER BY Name';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Round__c> scope) {
		Set<Id> parentIds = new Set<Id>();
		Set<Id> parentProductsIds = new Set<Id>();
		Set<Id> partnerIds = new Set<Id>();
		Set<Id> partnerProductsIds = new Set<Id>();

		DailyDispatch__c dispatch;
		List<DailyDispatch__c> dispatches = new List<DailyDispatch__c>();
		Map<Id, DailyDispatch__c> roundToDispatchMap = new Map<Id, DailyDispatch__c>();
		for (Round__c round : scope) {
			dispatch = new DailyDispatch__c(RoundId__c = round.Id, Name = round.Name + ' ' + TODAY_DATE, RoundStartTime__c = NOW, EndTime__c = NOW);
			dispatches.add(dispatch);
			roundToDispatchMap.put(round.Id, dispatch);

			for (Schedule__c collection : round.Collections__r) {
				if (collection.Discount_Type__c == 'Partner' && collection.Location__r.Partnership__c != null) {
					partnerIds.add(collection.Location__r.Partnership__c);
					partnerProductsIds.add(collection.Supplier_Product__r.Product__c);
				} else if (collection.Discount_Type__c == 'Account') {
					parentIds.add(collection.Location__r.ParentId);
					parentProductsIds.add(collection.Supplier_Product__r.Product__c);
				}
			}
		}
		INSERT dispatches;

		List<DispatchLocation__c> dispatchLocations = new List<DispatchLocation__c>();
		for (Round__c round : scope) {
			dispatchLocations.addAll(createDispatchLocations(roundToDispatchMap.get(round.Id), round));
		}
		INSERT dispatchLocations;

		Map<String, Account_Discount__c> partnerDiscountMap = AccountUtil.getDiscounts(partnerIds, partnerProductsIds);
		Map<String, Account_Discount__c> parentDiscountMap = AccountUtil.getDiscounts(parentIds, parentProductsIds);

		Collection_Waypoints__c waypoint;
		String partnerKey;
		String parentKey;
		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();
		for (Round__c round : scope) {
			dispatch = roundToDispatchMap.get(round.Id);
			for (Schedule__c collection : round.Collections__r) {
				waypoint = new Collection_Waypoints__c(Round__c = round.Id, Daily_Dispatch__c = dispatch.Id, Collection_Schedule__c = collection.Id,
					Name = collection.Name,  CreatedById = collection.CreatedById, Is_bin_collection__c = collection.Is_bin_collection__c,
					StartDate__c = collection.Start_Date__c, EndDate__c = collection.End_Date__c, Collection_Quantity__c = collection.Collection_Quantity__c, Discount_Type__c = collection.Discount_Type__c,
					Location__c = collection.Location__c, List_Price__c = collection.List_Price__c, Supplier_Product__c = collection.Supplier_Product__c);

				if (collection.Enqix_Price__c != null) {
					waypoint.Manual_Price__c = collection.Enqix_Price__c;
				}

				if (collection.Supplier__c != null && collection.Supplier__c != FIRST_MILE_SUPPLIER_ID) {
					waypoint.Supplier__c = collection.Supplier__c;
				}

				partnerKey = collection.Location__r.Partnership__c + '-' + collection.Supplier_Product__r.Product__c;
				parentKey = collection.Location__r.ParentId + '-' + collection.Supplier_Product__r.Product__c;
				if (collection.Discount_Type__c == 'Partner' && partnerDiscountMap.containsKey(partnerKey)) {
					waypoint.Account_Discount__c = partnerDiscountMap.get(partnerKey).Id;
				} else if (collection.Discount_Type__c == 'Account' && parentDiscountMap.containsKey(parentKey)) {
					waypoint.Account_Discount__c = parentDiscountMap.get(parentKey).Id;
				}

				waypoints.add(waypoint);
			}
		}

		INSERT waypoints;
	}

	private List<DispatchLocation__c> createDispatchLocations(DailyDispatch__c dispatch, Round__c round) {
		Map<Id, DispatchLocationWrapper> locationMap = new Map<Id, DispatchLocationWrapper>();
		for (Schedule__c collection : round.Collections__r) {
			if (locationMap.containsKey(collection.Location__c)) {
				locationMap.get(collection.Location__c).collate(collection);
			} else {
				locationMap.put(collection.Location__c, new DispatchLocationWrapper(dispatch.Id, collection));
			}
		}

		List<DispatchLocation__c> dispatchLocations = new List<DispatchLocation__c>();
		for (DispatchLocationWrapper wrapper : locationMap.values()) {
			dispatchLocations.add(wrapper.convert(SERVICE_TIME));
		}
		return dispatchLocations;
	}

	public void finish(Database.BatchableContext BC) {}

	private class DispatchLocationWrapper {
		private Id dispatchId;
		private Id locationId;
		private Boolean isManaged;
		private Boolean isInternal;
		private Decimal binCount;
		private Time earliestArrival;
		private Time latestArrival;

		private DispatchLocationWrapper(Id dispatchId, Schedule__c collection) {
			this.dispatchId = dispatchId;
			locationId = collection.Location__c;
			isManaged = collection.Location__r.Parent.Account_Manager__c != null;
			isInternal = collection.Is_Internal_Collection__c;
			binCount = !isInternal && collection.Is_bin_collection__c ? collection.Collection_Quantity__c : 0;
			earliestArrival = collection.EarliestArrival__c;
			latestArrival = collection.LatestArrival__c;
		}

		private void collate(Schedule__c collection) {
			isInternal = isInternal || collection.Is_Internal_Collection__c;
			binCount = !isInternal && collection.Is_bin_collection__c ? binCount + collection.Collection_Quantity__c : 0;
			earliestArrival = earliestArrival == null ? collection.EarliestArrival__c : (collection.EarliestArrival__c < earliestArrival ? collection.EarliestArrival__c : earliestArrival);
			latestArrival = latestArrival == null ? collection.LatestArrival__c : (collection.LatestArrival__c > latestArrival ? collection.LatestArrival__c : latestArrival);
		}

		private DispatchLocation__c convert(CollectionServiceTimeSetting__c settings) {
			return new DispatchLocation__c(Dispatch__c = dispatchId, Location__c = locationId,
				ServiceTime__c = isInternal ? settings.Internal__c : (binCount > 0 ? binCount * settings.Bin__c : (isManaged ? settings.BagsBigAccount__c : settings.BagsSmallAccount__c)),
				EarliestArrival__c = earliestArrival, LatestArrival__c = latestArrival);
		}
	}
}