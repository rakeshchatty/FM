public without sharing class BinWeightMatchToWaypointBatch implements Database.Batchable<sObject> {

	private Map<Id, BinWeight__c> binWeightsToUpdate = new Map<Id, BinWeight__c>();
	private List<BinWeight__c> noMatchWeights;
	private Map<String, List<BinWeight__c>> binWeightMap;
	private Map<String, OrderItem> orderProductMap;

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT Date__c, Location__c, CategoryCode__c FROM BinWeight__c
			WHERE Status__c = 'New' AND Weight__c = null AND (DAY_ONLY(Date__c) >= LAST_N_DAYS:8 OR Date__c = THIS_MONTH)]);
	}

	public void execute(Database.BatchableContext bc, List<BinWeight__c> scope) {
		// First match is based on Date__c itself
		match(scope);
		// Second match is Date__c + 1 day
		if (!noMatchWeights.isEmpty()) {
			for (BinWeight__c binWeight : noMatchWeights) {
				binWeight.Date__c += 1;
			}
			match(noMatchWeights);
		}

		Integer count = 2;
		// 3rd to 7th match is days before Date__c
		while (count < 8 && !noMatchWeights.isEmpty()) {
			for (BinWeight__c binWeight : noMatchWeights) {
				binWeight.Date__c -= (count == 2) ? 2 : 1;
			}

			match(noMatchWeights);
			count++;
		}

		UPDATE binWeightsToUpdate.values();
	}

	public void finish(Database.BatchableContext bc) {
		Database.executeBatch(new BinWeightToWeightBatch(), 1000);
	}

	private void match(List<BinWeight__c> binWeights) {
		prepareMatchMaps(binWeights);

		noMatchWeights = new List<BinWeight__c>();

		for (String key : binWeightMap.keySet()) {
			if (!orderProductMap.containsKey(key)) {
				for (BinWeight__c binWeight : binWeightMap.get(key)) {
					noMatchWeights.add(binWeight);
					binWeightsToUpdate.put(binWeight.Id, new BinWeight__c(Id = binWeight.Id, OrderProduct__c = null, Collection_Waypoint__c = null, Status__c = 'No match'));
				}
				continue;
			}

			OrderItem matchedOrderProduct = orderProductMap.get(key);
			for (BinWeight__c binWeight : binWeightMap.get(key)) {
				binWeightsToUpdate.put(binWeight.Id, new BinWeight__c(Id = binWeight.Id, OrderProduct__c = matchedOrderProduct.Id, Collection_Waypoint__c = matchedOrderProduct.Collection_Waypoint__c, Status__c = 'Matched'));
			}
		}
	}

	private void prepareMatchMaps(List<BinWeight__c> binWeights) {
		Set<Date> dates = new Set<Date>();
		Set<String> locationIds = new Set<String>();
		Set<String> categoryCodes = new Set<String>();

		binWeightMap = new Map<String, List<BinWeight__c>>();
		for (BinWeight__c binWeight : binWeights) {
			dates.add(binWeight.Date__c.date());
			locationIds.add(binWeight.Location__c);
			categoryCodes.add(binWeight.CategoryCode__c);

			String key = binWeight.Date__c.date() + '_' + binWeight.Location__c + '_' + binWeight.CategoryCode__c;
			if (binWeightMap.containsKey(key)) {
				binWeightMap.get(key).add(binWeight);
			} else {
				binWeightMap.put(key, new List<BinWeight__c>{binWeight});
			}
		}

		List<OrderItem>	orderProducts = [SELECT Order.AccountId, CollectionDate__c, Product2.BinCategoryCode__c, Total_KG_from_Weights__c, Collection_Waypoint__c FROM OrderItem
			WHERE CollectionDate__c IN :dates AND Order.AccountId IN :locationIds AND Product2.BinCategoryCode__c IN :categoryCodes];

		orderProductMap = new Map<String, OrderItem>();
		for (OrderItem orderItem : orderProducts) {
			String key = orderItem.CollectionDate__c + '_' + orderItem.Order.AccountId + '_' + orderItem.Product2.BinCategoryCode__c;
			orderProductMap.put(key, orderItem);
		}
	}
}