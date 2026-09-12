public class DispatchCreationBatch implements Database.Batchable<sObject>, Database.Stateful {

	private final DateTime NOW = System.now();
	private final String TODAY_DATE = NOW.format('dd/MM/yyyy');
	private final Id FIRST_MILE_SUPPLIER_ID = [SELECT Id FROM Suppliers__c WHERE Name = 'First Mile Ltd' LIMIT 1].Id;
	private final List<String> EMAIL_RECIPIENT = new List<String>{'fm.salesforce.errors@xperiensys.com', 'Louise.LeBesnerais@thefirstmile.co.uk'};
	private final Set<Id> roundIds;

	public DispatchCreationBatch() {}

	public DispatchCreationBatch(Set<Id> roundIds) {
		this.roundIds = roundIds;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Name,' +
				' (SELECT Name, CreatedById, Is_bin_collection__c, Is_Internal_Collection__c, Start_Date__c, End_Date__c, Collection_Quantity__c, Discount_Type__c, Time__c, EarliestArrival__c, LatestArrival__c,' +
				' Location__c, Location__r.ParentId, Location__r.Parent.Account_Manager__c, Location__r.Partnership__c, List_Price__c, Enqix_Price__c, SupplierUnitPrice__c, Supplier__c, Supplier_Product__c, Supplier_Product__r.Product__c' +
				' FROM Collections__r WHERE Collection_Active__c = true AND Collection_today__c = true' +
				' ORDER BY Location__c)' +
			' FROM Round__c WHERE IsActiveToday__c = true {0} ORDER BY Name';

		if (roundIds == null) {
			query = String.format(query, new List<String>{''});
		} else {
			query = String.format(query, new List<String>{'AND Id IN :roundIds'});
		}
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Round__c> scope) {
		Set<Id> parentIds = new Set<Id>();
		Set<Id> parentProductsIds = new Set<Id>();
		Set<Id> partnerIds = new Set<Id>();
		Set<Id> partnerProductsIds = new Set<Id>();

		Map<Id, DailyDispatch__c> roundToDispatchMap = new Map<Id, DailyDispatch__c>();
		for (Round__c round : scope) {
			roundToDispatchMap.put(round.Id, new DailyDispatch__c(RoundId__c = round.Id, Name = round.Name + ' ' + TODAY_DATE, RoundStartTime__c = NOW, EndTime__c = NOW));

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
		Database.SaveResult[] results = Database.insert(roundToDispatchMap.values(), false);
		LogRegister.createLogsUpsert(results, roundToDispatchMap.values(), 'Create Dispatches', 'Insert', 'DailyDispatch__c', 'RoundId__c');

		Map<String, DispatchLocation__c> dispatchLocationMap = new Map<String, DispatchLocation__c>();
		for (Round__c round : scope) {
			dispatchLocationMap.putAll(CreateDispatchLocation.create(round, roundToDispatchMap.get(round.Id).Id));
		}
		results = Database.insert(dispatchLocationMap.values(), false);
		LogRegister.createLogsUpsert(results, dispatchLocationMap.values(), 'Create Dispatch Locations', 'Insert', 'DispatchLocation__c', 'DailyDispatch__c');

		Map<String, Account_Discount__c> partnerDiscountMap = AccountUtil.getDiscounts(partnerIds, partnerProductsIds);
		Map<String, Account_Discount__c> parentDiscountMap = AccountUtil.getDiscounts(parentIds, parentProductsIds);

		Id dispatchId;
		Collection_Waypoints__c waypoint;
		String partnerKey;
		String parentKey;
		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();
		for (Round__c round : scope) {
			dispatchId = roundToDispatchMap.get(round.Id).Id;
			for (Schedule__c collection : round.Collections__r) {
				waypoint = new Collection_Waypoints__c(Daily_Dispatch__c = dispatchId, Collection_Schedule__c = collection.Id,
					DispatchLocation__c = dispatchLocationMap.get(CreateDispatchLocation.key(dispatchId, collection.Location__c)).Id,
					Name = collection.Name,  CreatedById = collection.CreatedById, Is_bin_collection__c = collection.Is_bin_collection__c,
					StartDate__c = collection.Start_Date__c, EndDate__c = collection.End_Date__c, Collection_Quantity__c = collection.Collection_Quantity__c, Discount_Type__c = collection.Discount_Type__c,
					Location__c = collection.Location__c, List_Price__c = collection.List_Price__c, Supplier_Product__c = collection.Supplier_Product__c);

				if (collection.Enqix_Price__c != null) {
					waypoint.Manual_Price__c = collection.Enqix_Price__c;
				}

				if (collection.SupplierUnitPrice__c != null) {
					waypoint.SupplierUnitPrice__c = collection.SupplierUnitPrice__c;
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
		results = Database.insert(waypoints, false);
		LogRegister.createLogsUpsert(results, waypoints, 'Create Waypoints', 'Insert', 'Schedule__c', 'Daily_Dispatch__c');
	}

	public void finish(Database.BatchableContext BC) {
		checkMissedDispatches();

		DispatchSequence.sequenceMorningDispatches();

		setFirstCollectionDate();
	}

	private void checkMissedDispatches() {
		Set<Round__c> missedRounds = new Set<Round__c>();
		List<Round__c> rounds = [SELECT Name, (SELECT Id FROM DailyRounds__r WHERE CreatedDate = TODAY) FROM Round__c WHERE IsActiveToday__c = true];
		for (Round__c round : rounds) {
			if (round.DailyRounds__r.isEmpty()) {
				missedRounds.add(round);
			}
		}

		if (missedRounds.isEmpty()) {
			return;
		}

		Messaging.SingleEmailMessage errorMail = new Messaging.SingleEmailMessage();
		errorMail.setToAddresses(EMAIL_RECIPIENT);
		errorMail.setOrgWideEmailAddressId([SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@thefirstmile.co.uk'].Id);
		errorMail.setSubject('Dispatch not created for today\'s Rounds - ' + System.today());
		String emailBody = '';
		for (Round__c round : missedRounds) {
				emailBody += round.Name + ' : ' + URL.getOrgDomainUrl().toExternalForm() + '/' + round.Id + '\n';
		}
		errorMail.setPlainTextBody(emailBody);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {errorMail});
	}

	private void setFirstCollectionDate() {
		Database.executebatch(new LocationFirstCollectionDateBatch(), 20);
	}
}