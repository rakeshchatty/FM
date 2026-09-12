public without sharing class BinLiftToWeightBatch implements Database.Batchable<sObject>, Database.Stateful {

	private Map<String, List<String>> categoryToWeightFields = new Map<String, List<String>>();

	public Database.QueryLocator start(Database.BatchableContext BC) {
		for (WeightCategoryToFieldMapping__mdt mapping : [SELECT Label, WeightFieldName__c FROM WeightCategoryToFieldMapping__mdt]) {
			categoryToWeightFields.put(mapping.Label, mapping.WeightFieldName__c.split(','));
		}

		return Database.getQueryLocator([SELECT Id,
			(SELECT Key__c, CollectedAt__c, WasteCategoryCode__c, Kilogram__c FROM BinLifts__r WHERE Status__c = 'Matched')
			FROM OrderItem WHERE Id IN (SELECT OrderProduct__c FROM BinLift__c WHERE Status__c = 'Matched')]);
	}

	public void execute(Database.BatchableContext BC, List<OrderItem> scope) {
		List<Weight__c> weights = new List<Weight__c>();
		for (OrderItem orderItem : scope) {
			for (BinLift__c binLift : orderItem.BinLifts__r) {
				Weight__c weight = new Weight__c(BinLift__c = binLift.Id, Order_Product__c = orderItem.Id, ServiceDate__c = binLift.CollectedAt__c);
				for (String weightFieldName : categoryToWeightFields.get(binLift.WasteCategoryCode__c)) {
					weight.put(weightFieldName.trim(), binLift.Kilogram__c);
				}
				weights.add(weight);
			}
		}
		INSERT weights;

		List<BinLift__c> binLifts = new List<BinLift__c>();
		for (Weight__c weight : weights) {
			binLifts.add(new BinLift__c(Id = weight.BinLift__c, Weight__c = weight.Id, Status__c = 'Weight Added'));
		}
		UPDATE binLifts;
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new BinSummaryOfWaypointBatch());
	}
}