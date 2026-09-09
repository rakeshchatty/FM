public without sharing class BinWeightToWeightBatch implements Database.Batchable<sObject>, Database.Stateful {

	private Map<String, List<String>> categoryToWeightFields = new Map<String, List<String>>();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		for (WeightCategoryToFieldMapping__mdt mapping : [SELECT Label, WeightFieldName__c FROM WeightCategoryToFieldMapping__mdt]) {
			categoryToWeightFields.put(mapping.Label, mapping.WeightFieldName__c.split(','));
		}

		return Database.getQueryLocator([SELECT Id,
			(SELECT Id, Date__c, CategoryCode__c, Kilogram__c FROM Bin_Weights__r),
			(SELECT Id FROM Order_Products__r LIMIT 1)
			FROM Collection_Waypoints__c
			WHERE Id IN (SELECT Collection_Waypoint__c FROM BinWeight__c WHERE Status__c = 'New') AND Order_Created__c = true]);
	}

	public void execute(Database.BatchableContext BC, List<Collection_Waypoints__c> scope) {
		Map<Id, Weight__c> weightsMap = new Map<Id, Weight__c>();
		for (Collection_Waypoints__c waypoint : scope) {
			for (BinWeight__c binWeight : waypoint.Bin_Weights__r) {
				Weight__c weight = new Weight__c(Order_Product__c = waypoint.Order_Products__r[0].Id, ServiceDate__c = binWeight.Date__c);
				if (!categoryToWeightFields.containsKey(binWeight.CategoryCode__c)) {
					continue;
				}
				for (String weightFieldName : categoryToWeightFields.get(binWeight.CategoryCode__c)) {
					weight.put(weightFieldName.trim(), binWeight.Kilogram__c);
				}
				weightsMap.put(binWeight.Id, weight);
			}
		}
		INSERT weightsMap.values();

		List<BinWeight__c> binWeights = new List<BinWeight__c>();
		for (Id binWeightId : weightsMap.keySet()) {
			Weight__c weight = weightsMap.get(binWeightId);
			binWeights.add(new BinWeight__c(Id = binWeightId, Weight__c = weight.Id, OrderProduct__c = weight.Order_Product__c,  Status__c = 'Matched'));
		}
		UPDATE binWeights;
	}

	public void finish(Database.BatchableContext BC) {}
}