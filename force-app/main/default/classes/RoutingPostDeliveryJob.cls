public without sharing class RoutingPostDeliveryJob extends RoutingPostJob {

	private Id orderGroupId;

	public RoutingPostDeliveryJob(Id orderGroupId) {
		this.orderGroupId = orderGroupId;
	}

	protected override RoutingRequest createRequest() {
		RoutingParameterOverride__mdt overrides = RoutingParameterOverride.get('Delivery');

		List<DeliveryOrder__c> orders = [SELECT Order__r.OrderNumber, Order__r.Account.Name, Order__r.ShippingStreetLineSingle__c, Order__r.ShippingPostalCode,
			Order__r.ShippingLatitude, Order__r.ShippingLongitude, ServiceTime__c, Demand__c, ServiceType__c, SkillSet__c
			FROM DeliveryOrder__c WHERE DeliveryOrderGroup__c = :orderGroupId];

		Id deliveryRouteGroupId = [SELECT DeliveryRouteGroup__c FROM DeliveryOrderGroup__c WHERE Id = :orderGroupId].DeliveryRouteGroup__c;
		List<DeliveryRoute__c> routes = [SELECT Name, StartTime__c, MaxRouteTime__c, VehicleCapacity__c, StartDepot__r.Index__c, EndDepot__r.Index__c, Preference__c, SkillSet__c
			FROM DeliveryRoute__c WHERE DeliveryRouteGroup__c = :deliveryRouteGroupId];

		overrides.NumberOfRoutes__c = routes.size();

		Set<Id> depotIds = IdUtil.extractId(routes, 'StartDepot__c');
		List<Depot__c> depots = [SELECT Index__c, Name, Address__Street__s, Address__City__s, Address__PostalCode__s, Coordinates__Latitude__s, Coordinates__Longitude__s
			FROM Depot__c WHERE Id IN :depotIds];

		return new RoutingRequestDelivery(overrides, depots, orders, routes);
	}

	protected override void updateJobError(String status, String message) {
		updateJob(new DeliveryOrderGroup__c(RoutingStatus__c = status, RoutingResponse__c = message));
	}

	protected override void processResult(RoutingResponse routingResponse) {
		updateJob(new DeliveryOrderGroup__c(RoutingJobId__c = routingResponse.jobId, RoutingStatus__c = 'In Progress',
			RoutingPollCount__c = 0, RoutingResponse__c = null, RoutingSummary__c = null));

		System.enqueueJob(new RoutingGetDeliveryResultQueueable(routingResponse.jobId), 1);
	}

	private void updateJob(DeliveryOrderGroup__c deliveryOrderGroup) {
		deliveryOrderGroup.Id = orderGroupId;
		UPDATE deliveryOrderGroup;
	}
}