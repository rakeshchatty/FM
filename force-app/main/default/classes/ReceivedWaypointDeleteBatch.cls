public class ReceivedWaypointDeleteBatch implements Database.Batchable<sObject> {

	@InvocableMethod(label='Delete Older Received Waypoints')
	public static void deleteOlderReceivedWaypoints() {
		Database.executeBatch(new ReceivedWaypointDeleteBatch(), 2000);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id FROM ReceivedWaypoint__c WHERE CreatedDate < LAST_N_DAYS:30';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		Database.delete(scope, false);
	}

	public void finish(Database.BatchableContext BC) {
		DELETE [SELECT Id FROM ReceivedWaypointGroup__c WHERE CreatedDate < LAST_N_DAYS:30];
	}
}