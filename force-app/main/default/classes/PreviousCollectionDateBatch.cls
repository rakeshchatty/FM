public without sharing class PreviousCollectionDateBatch implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT NextCollectionDate__c, WeekFrequency__c FROM Schedule__c WHERE NextCollectionDate__c != null AND NextCollectionDate__c <= TODAY AND (End_Date__c >= TODAY OR End_Date__c = null) ORDER BY Location__c]);
	}

	public void execute(Database.BatchableContext batchContext, List<Schedule__c> schedules) {
		for (Schedule__c schedule : schedules) {
			schedule.PreviousCollectionDate__c = computePreviousCollectionDate(schedule.NextCollectionDate__c, Integer.valueOf(schedule.WeekFrequency__c));
		}

		Database.SaveResult[] results = Database.update(schedules, false);
		LogRegister.createLogsUpsert(results, schedules, 'Set Previous Collection Date', 'Update', 'Schedule__c', null);
	}

	public void finish(Database.BatchableContext batchContext) {}

	@TestVisible
	private Date computePreviousCollectionDate(Date nextCollectionDate, Integer weekFrequency) {
		Date previousCollectionDate;
		do {
			previousCollectionDate = nextCollectionDate;
			nextCollectionDate = previousCollectionDate.addDays(Integer.valueOf(7 * weekFrequency));
		} while (nextCollectionDate <= Date.today());

		return previousCollectionDate;
	}
}