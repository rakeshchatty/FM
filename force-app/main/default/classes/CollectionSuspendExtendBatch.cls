public without sharing class CollectionSuspendExtendBatch implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT SuspensionDate__c, ReactivationDate__c FROM ScheduleSuspension__c WHERE IsActive__c = true AND IsEveryYear__c = true AND ReactivationDate__c < TODAY';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<ScheduleSuspension__c> scope) {
		for (ScheduleSuspension__c suspension : scope) {
			suspension.SuspensionDate__c = suspension.SuspensionDate__c.addYears(1);
			suspension.ReactivationDate__c = suspension.ReactivationDate__c.addYears(1);
		}

		Database.SaveResult[] result = Database.update(scope, false);
		LogRegister.createLogsUpsert(result, scope, 'Update suspension/reactivation dates', 'Update', 'ScheduleSuspension__c', null);
	}

	public void finish(Database.BatchableContext BC) {}
}