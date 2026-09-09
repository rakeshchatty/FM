public with sharing class SalesforceObjectsBatch implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		String query = 'SELECT Id, Name FROM SalesforceObject__c WHERE NumberOfRecords__c = null';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<SalesforceObject__c> sfObjects) {
		for (SalesforceObject__c obj : sfObjects) {
			try {
                AggregateResult agList = Database.query('SELECT Count(Id) NumberOfRecords, MIN(CreatedDate) Oldest, MAX(CreatedDate) Latest FROM '+Obj.Name);
                obj.NumberOfRecords__c = (Decimal)agList.get('NumberOfRecords');
                obj.Oldest__c = String.valueOf(agList.get('Oldest')); 
                obj.Latest__c = String.valueOf(agList.get('Latest'));
            } Catch(Exception e) {}
		}
		Database.update(sfObjects, false);
	}

	public void finish(Database.BatchableContext batchContext) {}
}