public without sharing class RoutingRequestDelivery extends RoutingRequest {

	private List<Location> serviceLocations = new List<Location>();
	private List<Route> routeSet = new List<Route>();

	public RoutingRequestDelivery(RoutingParameterOverride__mdt overrides, List<Depot__c> depots, List<DeliveryOrder__c> deliveryOrders, List<DeliveryRoute__c> routes) {
		super(overrides, depots);

		for (DeliveryOrder__c deliveryOrder : deliveryOrders) {
			serviceLocations.add(new Location(deliveryOrder));
		}

		for (DeliveryRoute__c route : routes) {
			routeSet.add(new Route(route));
		}
	}

	private class Location {
		private transient DeliveryOrder__c deliveryOrder;

		private Location(DeliveryOrder__c deliveryOrder) {
			this.deliveryOrder = deliveryOrder;
		}

		private Integer recordID { get { return Convert.toInteger(deliveryOrder.Order__r.OrderNumber); } }
		private String customerName { get { return deliveryOrder.Order__r.Account.Name; } }
		private String address { get { return deliveryOrder.Order__r.ShippingStreetLineSingle__c; } }
		private String zipCode { get { return deliveryOrder.Order__r.ShippingPostalCode; } }
		private Decimal clientXCoord { get { return deliveryOrder.Order__r.ShippingLongitude; } }
		private Decimal clientYCoord { get { return deliveryOrder.Order__r.ShippingLatitude; } }
		private Integer serviceTime { get { return Convert.toInteger(deliveryOrder.ServiceTime__c); } }
		private List<Decimal> demand { get { return new List<Decimal>{deliveryOrder.Demand__c}; } }
		private String serviceType { get { return deliveryOrder.ServiceType__c; } }
		private List<String> skillSetProperties { get { return Convert.toList(deliveryOrder.SkillSet__c, ','); } }
	}

	private class Route {
		private transient DeliveryRoute__c route;

		private Route(DeliveryRoute__c route) {
			this.route = route;
		}

		private String routeId { get { return route.Name; } }
		private String startTime { get { return route.StartTime__c; } }
		private String maxRouteTime { get { return route.MaxRouteTime__c; } }
		private List<Decimal> vehicleCapacity { get { return new List<Decimal>{route.VehicleCapacity__c}; } }
		private Decimal startLocation { get { return Convert.toInteger(route.StartDepot__r.Index__c); } }
		private Decimal endLocation { get { return Convert.toInteger(route.EndDepot__r.Index__c); } }
		private Integer rtePref { get { return Convert.toInteger(route.Preference__c); } }
		private List<String> skillSetProperties { get { return Convert.toList(route.SkillSet__c, ','); } }
	}
}