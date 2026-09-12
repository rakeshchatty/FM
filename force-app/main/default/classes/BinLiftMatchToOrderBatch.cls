public without sharing class BinLiftMatchToOrderBatch implements Database.Batchable<sObject> {

	private Map<Id, BinLift__c> binLiftsToUpdate = new Map<Id, BinLift__c>();
	private List<BinLift__c> noMatchLifts;
	private Map<String, List<BinLift__c>> binLiftMap;
	private Map<String, OrderItem> orderProductMap;

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT CollectedAt__c, Location__c, WasteCategoryCode__c, Status__c, AllowedWeight__c FROM BinLift__c WHERE Status__c IN ('New', 'Attempt 1') AND DAY_ONLY(CollectedAt__c) >= 2026-05-01]);
	}

	public void execute(Database.BatchableContext bc, List<BinLift__c> scope) {
		// First match is based on CollectedAt__c itself
		match(scope);

		// Second match is CollectedAt__c + 1 day
		if (!noMatchLifts.isEmpty()) {
			for (BinLift__c binLift : noMatchLifts) {
				binLift.CollectedAt__c += 1;
			}
			match(noMatchLifts);
		}

		Integer count = 2;
		// 3rd to 7th match is days before CollectedAt__c
		while (count < 8 && !noMatchLifts.isEmpty()) {
			for (BinLift__c binLift : noMatchLifts) {
				binLift.CollectedAt__c -= (count == 2) ? 2 : 1;
			}

			match(noMatchLifts);
			count++;
		}

		UPDATE binLiftsToUpdate.values();
	}

	public void finish(Database.BatchableContext bc) {
		Database.executeBatch(new BinLiftToWeightBatch(), 1000);
	}

	private void match(List<BinLift__c> binLifts) {
		prepareMatchMaps(binLifts);

		noMatchLifts = new List<BinLift__c>();

		for (String key : binLiftMap.keySet()) {
			if (!orderProductMap.containsKey(key)) {
				for (BinLift__c binLift : binLiftMap.get(key)) {
					noMatchLifts.add(binLift);
					binLiftsToUpdate.put(binLift.Id, new BinLift__c(Id = binLift.Id, Status__c = (binLift.Status__c == 'New' ? 'Attempt 1' : 'No match')));
				}
				continue;
			}

			OrderItem matchedOrderProduct = orderProductMap.get(key);
			for (BinLift__c binLift : binLiftMap.get(key)) {
				binLiftsToUpdate.put(binLift.Id, new BinLift__c(Id = binLift.Id, Status__c = 'Matched', OrderProduct__c = matchedOrderProduct.Id, AllowedWeight__c = matchedOrderProduct.AllowedWeight__c ?? binLift.AllowedWeight__c));
			}
		}
	}

	private void prepareMatchMaps(List<BinLift__c> binLifts) {
		Set<Date> dates = new Set<Date>();
		Set<String> locationIds = new Set<String>();
		Set<String> categoryCodes = new Set<String>();

		binLiftMap = new Map<String, List<BinLift__c>>();
		for (BinLift__c binLift : binLifts) {
			dates.add(binLift.CollectedAt__c.date());
			locationIds.add(binLift.Location__c);
			categoryCodes.add(binLift.WasteCategoryCode__c);

			String key = binLift.CollectedAt__c.date() + '_' + binLift.Location__c + '_' + binLift.WasteCategoryCode__c;
			if (binLiftMap.containsKey(key)) {
				binLiftMap.get(key).add(binLift);
			} else {
				binLiftMap.put(key, new List<BinLift__c>{binLift});
			}
		}

		List<OrderItem>	orderProducts = [SELECT Order.AccountId, CollectionDate__c, Product2.BinCategoryCode__c, AllowedWeight__c FROM OrderItem
			WHERE CollectionDate__c IN :dates AND Order.AccountId IN :locationIds AND Product2.BinCategoryCode__c IN :categoryCodes];

		orderProductMap = new Map<String, OrderItem>();
		for (OrderItem orderItem : orderProducts) {
			String key = orderItem.CollectionDate__c + '_' + orderItem.Order.AccountId + '_' + orderItem.Product2.BinCategoryCode__c;
			orderProductMap.put(key, orderItem);
		}
	}
}