public without sharing class RoutingRequestCollection extends RoutingRequest {

	private List<Location> serviceLocations = new List<Location>();

	public RoutingRequestCollection(RoutingParameterOverride__mdt overrides, List<Depot__c> depots, List<DispatchLocation__c> locations) {
		super(overrides, depots);

		for (DispatchLocation__c location : locations) {
			serviceLocations.add(new Location(location));
		}
	}

	private class Location {
		private transient DispatchLocation__c location;

		private Location(DispatchLocation__c location) {
			this.location = location;
		}

		private Integer recordID { get { return Convert.toInteger(location.Name); } }
		private String customerName { get { return location.Location__r.Name; } }
		private String address { get { return location.Location__r.BillingStreetLineSingle__c; } }
		private String zipCode { get { return location.Location__r.BillingPostalCode; } }
		private Decimal clientXCoord { get { return location.Location__r.BillingLongitude; } }
		private Decimal clientYCoord { get { return location.Location__r.BillingLatitude; } }
		private Integer serviceTime { get { return Convert.toInteger(location.ServiceTime__c); } }
		private String earliestArrival { get { return Convert.toHhMm(location.EarliestArrival__c); } }
		private String latestArrival { get { return Convert.toHhMm(location.LatestArrival__c); } }
		private String existingRoute { get { return 'FM-Miley'; } }
	}
}