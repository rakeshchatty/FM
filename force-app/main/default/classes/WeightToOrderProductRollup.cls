public without sharing class WeightToOrderProductRollup {

	public static void processWeights(List<Weight__c> weights) {
		Set<Id> orderItemIds = new Set<Id>();
		for (Weight__c weight : weights) {
			orderItemIds.add(weight.Order_Product__c);
		}
		rollupWeights(orderItemIds);
	}

	private static void rollupWeights(Set<Id> orderItemIds) {
		List<AggregateResult> aggregatedWeights = [SELECT Order_Product__c,
			SUM(Coffee_KG_Per_Unit__c) CoffeeKGPerUnit, SUM(AD_KG_Per_Unit__c) ADKGPerUnit, SUM(Recycled_KG_Per_Unit__c) RecycledKGPerUnit,
			SUM(KWH_Produced_Per_Unit__c) KWHProducedPerUnit, SUM(WTE_KG_Per_Unit__c) WTEKGPerUnit,
			SUM(Tonnes_CO2_Saved_Per_Unit__c) TonnesCO2SavedPerUnit, SUM(Trees_Saved_Per_Unit__c) TreesSavedPerUnit,
			SUM(Total_KG_Per_Unit__c) TotalKGPerUnit, SUM(Overweight__c) Overweight
			FROM Weight__c
			WHERE Order_Product__c IN :orderItemIds
			GROUP BY Order_Product__c];

		Map<Id, OrderItem> orderItemMap = new Map<Id, OrderItem>();
		for (AggregateResult aggrWeight : aggregatedWeights) {
			OrderItem orderProduct = new OrderItem(Id = String.valueOf(aggrWeight.get('Order_Product__c')));
			orderProduct.Coffee_KG_from_Weights__c = (Decimal)aggrWeight.get('CoffeeKGPerUnit');
			orderProduct.AD_KG_from_Weights__c = (Decimal)aggrWeight.get('ADKGPerUnit');
			orderProduct.Recycled_KG_from_Weights__c = (Decimal)aggrWeight.get('RecycledKGPerUnit');
			orderProduct.KWH_Produced_from_Weights__c = (Decimal)aggrWeight.get('KWHProducedPerUnit');
			orderProduct.WTE_KG_from_Weights__c = (Decimal)aggrWeight.get('WTEKGPerUnit');
			orderProduct.Tonnes_CO2_Saved_from_Weights__c = (Decimal)aggrWeight.get('TonnesCO2SavedPerUnit');
			orderProduct.Trees_Saved_from_Weights__c = (Decimal)aggrWeight.get('TreesSavedPerUnit');
			orderProduct.Total_KG_from_Weights__c = (Decimal)aggrWeight.get('TotalKGPerUnit');
			orderProduct.Overweight__c = (Decimal)aggrWeight.get('Overweight');
			orderProduct.LastWeightModifiedDate__c = System.today();
			orderItemMap.put(orderProduct.Id, orderProduct);
		}

		for (Id orderItemId : orderItemIds) {
			if (!orderItemMap.containsKey(orderItemId)) {
				orderItemMap.put(orderItemId, resetOrderProduct(orderItemId));
			}
		}
		UPDATE orderItemMap.values();
	}

	private static OrderItem resetOrderProduct(Id orderItemId) {
		OrderItem orderItem = new OrderItem(Id = orderItemId,
			Coffee_KG_from_Weights__c = null, AD_KG_from_Weights__c = null, Recycled_KG_from_Weights__c = null,
			KWH_Produced_from_Weights__c = null,  WTE_KG_from_Weights__c = null,
			Tonnes_CO2_Saved_from_Weights__c = null, Trees_Saved_from_Weights__c = null,
			Total_KG_from_Weights__c = null);
		return orderItem;
	}
}