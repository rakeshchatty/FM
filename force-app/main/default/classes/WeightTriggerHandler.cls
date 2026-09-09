public without sharing class WeightTriggerHandler {

	public void handleTrigger(List<Weight__c> newList, Map<Id, Weight__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT, AFTER_UPDATE {
				WeightToOrderProductRollup.processWeights(newList);
			}
			when AFTER_DELETE {
				WeightToOrderProductRollup.processWeights(oldMap.values());
			}
		}
	}
}