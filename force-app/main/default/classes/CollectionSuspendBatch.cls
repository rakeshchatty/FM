public class CollectionSuspendBatch implements Database.Batchable<sObject> {
	@InvocableMethod(label='Collection Suspension/Reactivation Batch')
	public static void updateCollectionSuspendFlag() {
		Database.executeBatch(new CollectionSuspendBatch(), 1000);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Collection_Suspended__c FROM Schedule__c WHERE (Collection_Suspended__c = false AND Suspension_Start_Date__c <= TODAY AND Reactivation_Start_Date__c > TODAY) OR (Collection_Suspended__c = true AND Reactivation_Start_Date__c <= TODAY)';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Schedule__c> scope) {
		for (Schedule__c schedule : scope) {
			schedule.Collection_Suspended__c = !schedule.Collection_Suspended__c;
		}
		Database.update(scope, false);
	}

	public void finish(Database.BatchableContext BC) {
	}
}