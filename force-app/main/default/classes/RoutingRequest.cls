public without sharing abstract class RoutingRequest {

	private ParameterOverride parameterOverrides;
	private List<Depot> facilities = new List<Depot>();

	protected RoutingRequest(RoutingParameterOverride__mdt overrides, List<Depot__c> depots) {
		parameterOverrides = new ParameterOverride(overrides);

		for (Depot__c depot : depots) {
			facilities.add(new Depot(depot));
		}
	}

	private class ParameterOverride {
		private transient RoutingParameterOverride__mdt overrides;

		private ParameterOverride(RoutingParameterOverride__mdt overrides) {
			this.overrides = overrides;
		}

		private String solver { get { return overrides.Solver__c; } }
		private String generateMethod { get { return overrides.GenerateMethod__c; } }
		private Integer numberOfRoutes { get { return Convert.toInteger(overrides.NumberOfRoutes__c); } }
		private String maxRouteTime { get { return overrides.MaxRouteTime__c; } }
		private String startTime { get { return overrides.StartTime__c; } }
		private Integer startLocation { get { return Convert.toInteger(overrides.StartDepotIndex__c); } }
		private Integer endLocation { get { return Convert.toInteger(overrides.EndDepotIndex__c); } }
		private Integer seqStart { get { return Convert.toInteger(overrides.SequenceStart__c); } }
		private Integer seqGap { get { return Convert.toInteger(overrides.SequenceGap__c); } }
		private Boolean useExtraDistance { get { return Convert.toBoolean(overrides.UseExtraDistance__c); } }
		private Boolean useExtraTime { get { return Convert.toBoolean(overrides.UseExtraTime__c); } }
		private Boolean useSpecialties { get { return Convert.toBoolean(overrides.UseSpecialties__c); } }
		private Boolean usePickupDeliveryCapacity { get { return Convert.toBoolean(overrides.UsePickupDeliveryCapacity__c); } }
	}

	private class Depot {
		private transient Depot__c depot;

		private Depot(Depot__c depot) {
			this.depot = depot;
		}

		private Integer id { get { return Convert.toInteger(depot.Index__c); } }
		private String name { get { return depot.Name; } }
		private Decimal clientXCoord { get { return depot.Coordinates__Longitude__s; } }
		private Decimal clientYCoord { get { return depot.Coordinates__Latitude__s; } }
		private String address { get { return depot.Address__Street__s; } }
		private String city { get { return depot.Address__City__s; } }
		private String zipCode { get { return depot.Address__PostalCode__s; } }
	}
}