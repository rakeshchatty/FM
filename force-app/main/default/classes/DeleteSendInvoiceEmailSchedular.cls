public without sharing class DeleteSendInvoiceEmailSchedular implements Schedulable {

	public void execute(SchedulableContext SC) {
		String query = 'SELECT Id FROM SendInvoiceEmail__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query), 2000);
	}
}