public without sharing class DeleteGoogleAdsEventScheduler implements Schedulable {

	public void execute(SchedulableContext SC) {
		String query = 'SELECT Id FROM GoogleAdsEvent__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query), 10000);
	}
}