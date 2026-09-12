public without sharing class DeliveryOrderGroupTriggerHandler {

	public void handleTrigger(List<DeliveryOrderGroup__c> newList, Map<Id, DeliveryOrderGroup__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_UPDATE {
				handleUpdate(newList, oldMap);
			}
		}
	}

	private void handleUpdate(List<DeliveryOrderGroup__c> newList, Map<Id, DeliveryOrderGroup__c> oldMap) {
		List<DeliveryOrderGroup__c> requestedGroups = filter(newList, oldMap, 'Requested');
		if (!requestedGroups.isEmpty()) {
			Database.executebatch(new RoutingPostDeliveryJobBatch(IdUtil.extractId(requestedGroups)), 1);
		}

		List<DeliveryOrderGroup__c> completedGroups = filter(newList, oldMap, 'Completed');
		if (!completedGroups.isEmpty()) {
			createReceivedWaypoints(completedGroups);
		}
	}


	private List<DeliveryOrderGroup__c> filter(List<DeliveryOrderGroup__c> newList, Map<Id, DeliveryOrderGroup__c> oldMap, String status) {
		List<DeliveryOrderGroup__c> orderGroups = new List<DeliveryOrderGroup__c>();
		for (DeliveryOrderGroup__c orderGroup : newList) {
			if (orderGroup.RoutingStatus__c == status && oldMap.get(orderGroup.Id).RoutingStatus__c != status) {
				orderGroups.add(orderGroup);
			}
		}
		return orderGroups;
	}

	private void createReceivedWaypoints(List<DeliveryOrderGroup__c> orderGroups) {
		List<DeliveryOrder__c> deliveryOrders = [SELECT RouteDate__c, DeliveryOrderGroup__c , Order__c, DeliveryRoute__r.Name, SequenceNumber__c
			FROM DeliveryOrder__c WHERE DeliveryOrderGroup__c IN :orderGroups AND DeliveryRoute__c != null];
		List<ReceivedWaypoint__c> receivedWaypoints = new List<ReceivedWaypoint__c>();
		for (DeliveryOrder__c deliveryOrder : deliveryOrders) {
			ReceivedWaypoint__c receivedWaypoint = new ReceivedWaypoint__c(Source__c = 'RaaS', Date__c = deliveryOrder.RouteDate__c, Timestamp__c = deliveryOrder.DeliveryOrderGroup__c,
				Order__c = deliveryOrder.Order__c, Name = deliveryOrder.DeliveryRoute__r.Name, SequenceNumber__c = deliveryOrder.SequenceNumber__c);
			receivedWaypoints.add(receivedWaypoint);
		}
		INSERT receivedWaypoints;

		LIst<ReceivedWaypointGroup__c> receivedWaypointGroups = new List<ReceivedWaypointGroup__c>();
		for (DeliveryOrderGroup__c orderGroup : orderGroups) {
			receivedWaypointGroups.add(new ReceivedWaypointGroup__c(Source__c = 'RaaS', Date__c = orderGroup.RouteDate__c, Timestamp__c = orderGroup.Id));
		}
		INSERT receivedWaypointGroups;
	}
}