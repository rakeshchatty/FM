public with sharing class DeliveryOrderTriggerHandler {
    public void beforeUpdate(List<DeliveryOrder__c> deliveryOrders) {
        Map<String, List<Decimal>> streetSegIdSeqMap = new Map<String, List<Decimal>>();
        Map<Id, List<Decimal>> routeSeqMap = new Map<Id, List<Decimal>>();
        Map<Id, List<DeliveryOrder__c>> routeDeliveryOrderMap = new Map<Id, List<DeliveryOrder__c>>();
        for(DeliveryOrder__c deliveryOrder : deliveryOrders) {
            if(streetSegIdSeqMap.containsKey(deliveryOrder.StreetSegmentID__c)) {
                streetSegIdSeqMap.get(deliveryOrder.StreetSegmentID__c).add(deliveryOrder.SequenceNumber__c);
            }else {
                streetSegIdSeqMap.put(deliveryOrder.StreetSegmentID__c, new List<Decimal> {deliveryOrder.SequenceNumber__c});
            }
        }
        for(String key : streetSegIdSeqMap.keySet()) {
            streetSegIdSeqMap.get(key).sort();
            Decimal firstElement = streetSegIdSeqMap.get(key)[0];
            streetSegIdSeqMap.get(key).clear();
            streetSegIdSeqMap.get(key).add(firstElement);
        }
        for(DeliveryOrder__c deliveryOrder : deliveryOrders) {
            deliveryOrder.SequenceNumber__c = streetSegIdSeqMap.get(deliveryOrder.StreetSegmentID__c)[0];
            if(routeSeqMap.containsKey(deliveryOrder.DeliveryRoute__c)) {
                routeSeqMap.get(deliveryOrder.DeliveryRoute__c).add(deliveryOrder.SequenceNumber__c);
            }else {
                routeSeqMap.put(deliveryOrder.DeliveryRoute__c, new List<Decimal> {deliveryOrder.SequenceNumber__c});
            }
        }
        
        for(Id key : routeSeqMap.keySet()) {
            Integer index = 1;
            for(DeliveryOrder__c deliveryOrder : deliveryOrders) {
                if(deliveryOrder.DeliveryRoute__c == key) {

                }
            }
        }






        /*
        Set <Id> deliveryOrderIds = new Set<Id>();
        Map<String, String> segmentSequence = new Map<String, String>();
		for(DeliveryOrder__c deliveryOrder : deliveryOrders) {
			deliveryOrderIds.add(deliveryOrder.Id);
            segmentSequence.put(deliveryOrder.StreetSegmentID__c, deliveryOrder.SequenceNumber__c);
		}
        List<DeliveryOrder__c> todayDeliveryOrders = [SELECT Id, DeliveryRoute__c, StreetSegmentID__c, SequenceNumber__c FROM DelveryOrder__c WHERE CreatedDate = TODAY];
        Map<String, List<DeliveryOrder__c>> routeDeliveries = new Map<String, List<DeliveryOrder__c>>();
        for(DeliveryOrder__c deliveryOrder : todayDeliveryOrders) {
            if(routeDeliveries.contains(deliveryOrder.StreetSegmentID__c)) {
                routeDeliveries.get(deliveryOrder.StreetSegmentID__c).add(deliveryOrder);
            } else {
                routeDeliveries.put(deliveryOrder.StreetSegmentID__c, new List<DeliveryOrder__c> {deliveryOrder});
            }
        }

        for(String key : routeDeliveries.keySet()) {
            for(DeliveryOrder__c deliveryOrder : routeDeliveries.get(key)) {
                deliveryOrder.SequenceNumber__c = segmentSequence.get(key);
            }
        }
        */
	}
}