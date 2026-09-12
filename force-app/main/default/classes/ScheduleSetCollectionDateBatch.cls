public with sharing class ScheduleSetCollectionDateBatch implements Database.Batchable<sObject> {

	private final Date TODAY = Date.today();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM Schedule__c WHERE Id IN (SELECT Collection_Schedule__c FROM Collection_Waypoints__c WHERE CreatedDate = TODAY AND Type__c = \'Normal\') ORDER BY Location__c';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Schedule__c> schedules) {
		for (Schedule__c schedule : schedules) {
			schedule.PreviousCollectionDate__c = TODAY;
		}

		Database.SaveResult[] results = Database.update(schedules, false);
		LogRegister.createLogsUpsert(results, schedules, 'Set PreviousCollectionDate__c', 'Update', 'Schedule__c', null);
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new PreviousCollectionDateBatch());
	}
}