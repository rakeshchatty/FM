public without sharing class DeleteBinSummaryScheduler implements Schedulable{

	public void execute(SchedulableContext SC) {
		String query = 'SELECT Id FROM BinSummary__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query), 10000);
	}
}