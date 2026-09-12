public without sharing class RoutingGetDeliveryResult extends RoutingGetResult  {

	public RoutingGetDeliveryResult(Integer jobId, Integer pollCount) {
		super(jobId, pollCount);
	}

	protected override void enqueue() {
		updateJob(new DeliveryOrderGroup__c());

		if (Test.isRunningTest()) {return;} else {System.enqueueJob(new RoutingGetDeliveryResultQueueable(jobId, ++pollCount), 1);}
	}

	protected override void updateJobError(String status, String message) {
		updateJob(new DeliveryOrderGroup__c(RoutingStatus__c = status, RoutingResponse__c = message));
	}

	protected override void processResult(RoutingResponse routingResponse) {
		Map<String, DeliveryRoute__c> routeMap = new Map<String, DeliveryRoute__c>();
		List<DeliveryRoute__c> routes = [SELECT Name FROM DeliveryRoute__c WHERE DeliveryRouteGroup__c IN (SELECT DeliveryRouteGroup__c FROM DeliveryOrderGroup__c WHERE RoutingJobId__c = :routingResponse.jobId)];
		for (DeliveryRoute__c route : routes) {
			routeMap.put(route.Name, route);
		}

		Map<Integer, DeliveryOrder__c> deliveryOrderMap = new Map<Integer, DeliveryOrder__c>();
		List<DeliveryOrder__c> deliveryOrders = [SELECT Order__r.OrderNumber, Order__r.AccountId FROM DeliveryOrder__c WHERE DeliveryOrderGroup__r.RoutingJobId__c = :routingResponse.jobId];
		for (DeliveryOrder__c deliveryOrder : deliveryOrders) {
			deliveryOrderMap.put(Convert.toInteger(deliveryOrder.Order__r.OrderNumber), deliveryOrder);
		}

		DeliveryRoute__c route;
		DeliveryOrder__c deliveryOrder;
		Map<Id, List<DeliveryOrder__c>> deliveryOrdersByRoute = new Map<Id, List<DeliveryOrder__c>>();
		for (RoutingResponse.ServiceLocation location : routingResponse.serviceLocations) {
			route = routeMap.get(location.route);
			if (route == null) {
				deliveryOrderMap.remove(location.recordID);
				continue;	// Posibly some data error, due to which RaaS did not assign a route
			}
			deliveryOrder = deliveryOrderMap.get(location.recordID);
			deliveryOrder.DeliveryRoute__c = route.Id;
			deliveryOrder.SequenceNumber__c = location.sequence;

			// Group by each route
			if (deliveryOrdersByRoute.containsKey(route.Id)) {
				deliveryOrdersByRoute.get(route.Id).add(deliveryOrder);
			} else {
				deliveryOrdersByRoute.put(route.Id, new List<DeliveryOrder__c>{deliveryOrder});
			}
		}

		for (List<DeliveryOrder__c> deliveryOrderGroup : deliveryOrdersByRoute.values()) {
			resequence(deliveryOrderGroup);
		}

		UPDATE deliveryOrderMap.values();
		updateJob(new DeliveryOrderGroup__c(RoutingStatus__c = 'Completed', RoutingSummary__c = JSON.serializePretty(routingResponse.routeSummary)));
	}

	protected override String key(sObject record) {
		return ((DeliveryOrder__c)record).Order__r.AccountId;
	}

	private void updateJob(DeliveryOrderGroup__c deliveryOrderGroup) {
		deliveryOrderGroup.RoutingJobId__c = jobId;
		deliveryOrderGroup.RoutingPollCount__c = pollCount;
		UPSERT deliveryOrderGroup RoutingJobId__c;
	}
}