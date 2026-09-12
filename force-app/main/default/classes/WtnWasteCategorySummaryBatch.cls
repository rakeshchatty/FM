public without sharing class WtnWasteCategorySummaryBatch implements Database.Batchable<sObject>  {

	private final Boolean ALL_RECORDS;
	private List<String> wtnIds;
	private List<Schedule__c> schedules;

	public WtnWasteCategorySummaryBatch() {
		this(false);
	}

	public WtnWasteCategorySummaryBatch(Boolean allRecords) {
		ALL_RECORDS = allRecords;
	}

	public WtnWasteCategorySummaryBatch(List<String> wtnIds) {
		this();
		this.wtnIds = wtnIds;
	}

	public WtnWasteCategorySummaryBatch(List<Schedule__c> schedules) {
		this();
		this.schedules = schedules;
	}

	public Database.QueryLocator start(Database.BatchableContext bc) {
		if (ALL_RECORDS) {
			return Database.getQueryLocator([SELECT Id FROM WTN_Waste_Category__c WHERE WTN__r.IsActive__c = true AND WTN__r.Name LIKE 'Season Ticket WTN%']);
		}

		if (wtnIds != null) {
			return Database.getQueryLocator([SELECT Id FROM WTN_Waste_Category__c WHERE WTN__c IN :wtnIds]);
		}

		if (schedules == null) {
			schedules = [SELECT WtnWasteCategory__c FROM Schedule__c WHERE WtnWasteCategory__c != null AND (Start_Date__c = TODAY OR End_Date__c = YESTERDAY)];
		}

		Set<Id> wtnWasteCategoryIds = new Set<Id>();
		for (Schedule__c schedule : schedules) {
			wtnWasteCategoryIds.add(schedule.WtnWasteCategory__c);
		}
		return Database.getQueryLocator([SELECT Id FROM WTN_Waste_Category__c WHERE Id IN :wtnWasteCategoryIds]);
	}

	public void execute(Database.BatchableContext bc, List<WTN_Waste_Category__c> scope) {
		List<WTN_Waste_Category__c> wtnWasteCategories = new List<WTN_Waste_Category__c>();
		for (AggregateResult ar : [SELECT WtnWasteCategory__c, SUM(Collection_Quantity__c) TotalQty FROM Schedule__c
				WHERE WtnWasteCategory__c IN :scope
				AND (Start_Date__c = null OR Start_Date__c <= TODAY)
				AND (End_Date__c = null OR End_Date__c >= TODAY)
				GROUP BY WtnWasteCategory__c]) {
			wtnWasteCategories.add(new WTN_Waste_Category__c(Id = (Id)ar.get('WtnWasteCategory__c'), Quantity__c = (Decimal)ar.get('TotalQty')));
		}
		Database.SaveResult[] results = Database.update(wtnWasteCategories, false);
		LogRegister.createLogsUpsert(results, wtnWasteCategories, 'WTN Waste Category Summary', 'Update', 'WTN_Waste_Category__c', null);
	}

	public void finish(Database.BatchableContext bc) {}
}