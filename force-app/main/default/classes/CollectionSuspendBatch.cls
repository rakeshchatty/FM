public without sharing class CollectionSuspendBatch implements Database.Batchable<sObject> {

	@InvocableMethod(label='Collection Suspension/Reactivation Batch')
	public static void updateCollectionSuspendFlag() {
		Database.executeBatch(new CollectionSuspendBatch(), 1000);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Aggregator__c, Aggregator__r.IsSuspended__c FROM ScheduleSuspension__c WHERE IsActive__c = true AND' +
			' ((Aggregator__r.IsSuspended__c = false AND SuspensionDate__c <= TODAY AND ReactivationDate__c > TODAY)' +
			' OR (Aggregator__r.IsSuspended__c = true AND ReactivationDate__c = TODAY))';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<ScheduleSuspension__c> scope) {
		Map<Id, CollectionAggregator__c> aggregatorsToUpdateMap = new Map<Id, CollectionAggregator__c>();

		for (ScheduleSuspension__c suspension : scope) {
			if(!aggregatorsToUpdateMap.containsKey(suspension.Aggregator__c)) {
				aggregatorsToUpdateMap.put(suspension.Aggregator__c, new CollectionAggregator__c(Id = suspension.Aggregator__c, IsSuspended__c = !suspension.Aggregator__r.IsSuspended__c));
			}
		}

		Database.SaveResult[] result = Database.update(aggregatorsToUpdateMap.values(), false);
		LogRegister.createLogsUpsert(result, aggregatorsToUpdateMap.values(), 'Update Collection Aggregator to suspend/reactivate', 'Update', 'CollectionAggregator__c', null);
	}

	public void finish(Database.BatchableContext BC) {
		Database.executebatch(new CollectionSuspendExtendBatch());
	}
}