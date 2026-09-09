public without sharing class DeleteDeliveryOrderScheduler implements Schedulable {
    
    public void execute(SchedulableContext SC) {
		String query1 = 'SELECT Id FROM DeliveryOrderGroup__c WHERE IsScheduledForDeletion__c = True';
		Database.executeBatch(new DeleteSObjectBatch(query1), 10000);

        String query2 = 'SELECT Id FROM DeliveryRouteGroup__c WHERE IsScheduledForDeletion__c = True';
		Database.executeBatch(new DeleteSObjectBatch(query2), 10000);
	}
}