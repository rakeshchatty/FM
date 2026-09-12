public without sharing class DeleteWeightronEventSchedular implements Schedulable {

	public void execute(SchedulableContext SC) {
		String query = 'SELECT Id FROM WeightronEvent__c WHERE IsScheduledForDeletion__c = true';
		Database.executeBatch(new DeleteSObjectBatch(query));
	}
}