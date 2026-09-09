global class SubscribedProductRefreshBatch implements Database.Batchable <sObject>, Database.Stateful {
    
    global String query;

    global SubscribedProductRefreshBatch(){
        query = 'SELECT Id, quantityOrdered__c, NextRefreshDate__c, Enqix_BID_Location_Limit_Period__c FROM Subscribed_Products__c WHERE NextRefreshDate__c != null and NextRefreshDate__c = Today and Enqix_BID_Location_Limit_Period__c != null';
    }

     global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext BC, List<Subscribed_Products__c> scope){
        system.debug('scope.size()---> '+ scope.size());
        
        List<Subscribed_Products__c> lista = new List<Subscribed_Products__c>();
        for(Subscribed_Products__c h : scope){
				h.quantityOrdered__c = 0;
                lista.add(h);
		}
        update lista;
    }

    global void finish(Database.BatchableContext BC) {
        System.debug('SubscribedProducts were updated successfully');
    }
}