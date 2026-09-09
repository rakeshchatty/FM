public class LogDeleteBatch implements Database.Batchable<sObject> {

	@InvocableMethod(label='Delete Older Logs')
	public static void deleteOlderLogs() {
		Database.executeBatch(new LogDeleteBatch(), 2000);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM Log__c WHERE IsScheduledForDeletion__c = true';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		Database.delete(scope, false);
	}

	public void finish(Database.BatchableContext BC) {
	}
}