public without sharing class CollectionScheduleWeeklyBatch implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT PreviousCollectionDate__c, NextCollectionDate__c, Location__c FROM Schedule__c
			WHERE WeekFrequency__c > '1' AND (PreviousCollectionDate__c = THIS_WEEK OR NextCollectionDate__c = NEXT_WEEK)
			ORDER BY Location__c]);
	}

	public void execute(Database.BatchableContext BC, List<Schedule__c> scope) {
		Date currentWeekStart = Date.today().toStartOfWeek();
		Date currentWeekEnd = currentWeekStart.addDays(6);
		Date nextWeekStart = currentWeekStart.addDays(7);
		Date nextWeekEnd = currentWeekEnd.addDays(7);

		for (Schedule__c schedule : scope) {
			if (schedule.PreviousCollectionDate__c >= currentWeekStart && schedule.PreviousCollectionDate__c <= currentWeekEnd) {
				schedule.Week_Off__c = true;
				continue;
			}

			if (schedule.NextCollectionDate__c >= nextWeekStart && schedule.NextCollectionDate__c <= nextWeekEnd) {
				schedule.Week_Off__c = false;
			}
		}

		Database.SaveResult[] results = Database.update(scope, false);
		LogRegister.createLogsUpsert(results, scope, 'Update Week Off on Schedule', 'Update', 'Schedule__c', 'Location__c');
	}

	public void finish(Database.BatchableContext BC) {}
}