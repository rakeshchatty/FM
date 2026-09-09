global without sharing class CollectionScheduleController {

	@AuraEnabled
	public static List<CollectionAggregator__c> getCollections(Id recordId) {
		return [SELECT Supplier_Product__c, Supplier_Product__r.Product_Name__c, Quantity__c,
					Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c,
					(SELECT Id, Days__c FROM Collections__r)
				FROM CollectionAggregator__c WHERE Location__c = :recordId
				ORDER BY Supplier_Product__r.Product_Name__c];
	}

	@AuraEnabled
	public static void deleteAllCollections(Id recordId) {
		DELETE [SELECT Id FROM Schedule__c WHERE Location__c = :recordId];
	}
}