public without sharing class DeleteDeliveryPackageSchedular implements Schedulable{

	public void execute(SchedulableContext SC) {
		String query1 = 'SELECT Id FROM DeliveryPackage__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query1));

		String query2 = 'SELECT Id FROM DeliveryPackageTrackingFile__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query2));
	}
}