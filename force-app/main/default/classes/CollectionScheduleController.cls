global without sharing class CollectionScheduleController {

	@AuraEnabled
	public static List<CollectionAggregator__c> getCollections(Id recordId) {
		List<CollectionAggregator__c> aggregators = [SELECT Supplier_Product__c, Supplier_Product__r.Product_Name__c, Quantity__c,
				(SELECT Id, Days__c, Time__c FROM Collections__r WHERE End_Date__c = null OR End_Date__c > TODAY)
			FROM CollectionAggregator__c WHERE Location__c = :recordId
			ORDER BY Supplier_Product__r.Product_Name__c];

		// Tactical fix to avoid expired schedules
		List<CollectionAggregator__c> filteredAggregators = new List<CollectionAggregator__c>();
		for (CollectionAggregator__c aggregator : aggregators) {
			if (aggregator.Collections__r.isEmpty()) {
				continue;
			}

			filteredAggregators.add(aggregator);
			for (Schedule__c schedule : aggregator.Collections__r) {
				aggregator.put(schedule.Days__c + '__c', schedule.Time__c);
			}
		}

		return filteredAggregators;
	}
}