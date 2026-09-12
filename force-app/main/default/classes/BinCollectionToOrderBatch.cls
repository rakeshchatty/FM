public without sharing class BinCollectionToOrderBatch implements Database.Batchable<sObject> {

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN
			(SELECT Location__c FROM Collection_Waypoints__c WHERE Location__r.Parent.MonthsInvoicedInAdvance__c = null
				AND Order_Created__c = false AND Location__r.Enqix_Dead_Live__c = 'Live'
				AND Is_bin_collection__c = true AND Type__c = 'Normal' AND (Daily_Dispatch__r.EndTime__c = TODAY OR Daily_Dispatch__r.EndTime__c = YESTERDAY))]);
	}

	public void execute(Database.BatchableContext batchContext, List<Account> locations) {
		new CreateOrderFromWaypoint(locations).create();
	}

	public void finish(Database.BatchableContext batchContext) {
        Database.executeBatch(new WasteDestinationBatch());
    }
}