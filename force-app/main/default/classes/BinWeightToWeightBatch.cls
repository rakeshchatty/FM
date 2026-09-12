public without sharing class BinWeightToWeightBatch implements Database.Batchable<sObject>, Database.Stateful {

	private Map<String, List<String>> categoryToWeightFields = new Map<String, List<String>>();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		for (WeightCategoryToFieldMapping__mdt mapping : [SELECT Label, WeightFieldName__c FROM WeightCategoryToFieldMapping__mdt]) {
			categoryToWeightFields.put(mapping.Label, mapping.WeightFieldName__c.split(','));
		}

		return Database.getQueryLocator([SELECT Id,
			(SELECT Id, Date__c, CategoryCode__c, Kilogram__c FROM BinWeights__r WHERE Status__c = 'Matched' AND Weight__c = null)
			FROM OrderItem
			WHERE Id IN (SELECT OrderProduct__c FROM BinWeight__c WHERE Status__c = 'Matched' AND Weight__c = null AND (DAY_ONLY(Date__c) >= LAST_N_DAYS:8 OR Date__c = THIS_MONTH))]);
	}

	public void execute(Database.BatchableContext BC, List<OrderItem> scope) {
		Map<Id, Weight__c> weightsMap = new Map<Id, Weight__c>();
		for (OrderItem orderItem : scope) {
			for (BinWeight__c binWeight : orderItem.BinWeights__r) {
				if (!categoryToWeightFields.containsKey(binWeight.CategoryCode__c)) {
					continue;
				}

				Weight__c weight = new Weight__c(BinWeight__c = binWeight.Id, Order_Product__c = orderItem.Id, ServiceDate__c = binWeight.Date__c);
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
			binWeights.add(new BinWeight__c(Id = binWeightId, Weight__c = weight.Id, Status__c = 'Weight Added'));
		}
		UPDATE binWeights;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new BinSummaryOfWaypointBatch());
	}
}