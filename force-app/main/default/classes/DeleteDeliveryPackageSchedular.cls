public without sharing class DeleteDeliveryPackageSchedular implements Schedulable{

	public void execute(SchedulableContext SC) {
		String query1 = 'SELECT Id FROM DeliveryPackage__c WHERE IsScheduledForDeletion__c = true AND IsFinalStatus__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query1), 2000);

		String query2 = 'SELECT Id FROM DeliveryPackageTrackingFile__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query2), 2000);		
	}
}