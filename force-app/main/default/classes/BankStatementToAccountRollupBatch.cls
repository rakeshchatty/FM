public without sharing class BankStatementToAccountRollupBatch implements Database.Batchable<sObject>, Database.Stateful {

	private Map<String, List<String>> categoryToWeightFields = new Map<String, List<String>>();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT Id FROM Account
		WHERE Id IN (SELECT Account__c FROM Bank_Statement__c WHERE Transaction_Type__c != 'Credit Note' AND Unallocated_Amount__c > 0)]);
	}

	public void execute(Database.BatchableContext BC, List<Account> scope) {
		List<Account> accountsToUpdate = new List<Account>();
		for (AggregateResult aggregateResult : [SELECT SUM(Unallocated_Amount__c) UnallocatedAmount, Account__c FROM Bank_Statement__c WHERE Account__c IN :scope AND Transaction_Type__c != 'Credit Note' AND Unallocated_Amount__c > 0 GROUP BY Account__c]) {
			accountsToUpdate.add(new Account(Id = (Id)aggregateResult.get('Account__c'), TotalUnallocatedAmount__c = (Decimal)aggregateResult.get('UnallocatedAmount')));
		}

		if (!accountsToUpdate.isEmpty()) {
			UPDATE accountsToUpdate;
		}
	}

	public void finish(Database.BatchableContext BC) {}
}