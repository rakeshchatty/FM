public without sharing class DeleteDispatchSchedular implements Schedulable {

	public void execute(SchedulableContext SC) {
		String query1 = 'SELECT Id FROM Collection_Waypoints__c WHERE CreatedDate < LAST_N_DAYS:31';
		Database.executeBatch(new DeleteSObjectBatch(query1), 10000);

		String query2 = 'SELECT Id FROM DispatchLocation__c WHERE CreatedDate < LAST_N_DAYS:31';
		Database.executeBatch(new DeleteSObjectBatch(query2), 10000);
	}
}