public without sharing class LocationFirstCollectionDateBatch implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		String query = 'SELECT Id FROM Account WHERE Id IN (SELECT Location__c FROM Schedule__c WHERE Location__r.FirstCollectionDate__c = null AND IsCollectionTomorrow__c = true)';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<Account> locations) {
		List<Account> locationsToUpdate = new List<Account>();

		Date tomorrow = Date.today() + 1;
		for (Account location : locations) {
			location.FirstCollectionDate__c = tomorrow;
			locationsToUpdate.add(location);
		}

		Database.SaveResult[] results = Database.update(locationsToUpdate, false);
		LogRegister.createLogsUpsert(results, locationsToUpdate, 'Update Location.FirstCollectionDate__c', 'Update', 'Account', null);
	}

	public void finish(Database.BatchableContext batchContext) {
		Database.executeBatch(new ScheduleSetCollectionDateBatch(), 20);
	}
}