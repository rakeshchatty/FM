public without sharing class CollectionLocation {

	private transient DispatchLocation__c dispatchLocation;
	private List<Item> items = new List<Item>();
	private Set<Id> clusteredLocations = new Set<Id>();

	public CollectionLocation(DispatchLocation__c dispatchLocation) {
		this.dispatchLocation = dispatchLocation;

		for (Collection_Waypoints__c waypoint : dispatchLocation.CollectionWaypoints__r) {
			items.add(new Item(waypoint));
		}
	}

	public CollectionLocation(List<DispatchLocation__c> dispatchLocations) {
		this(dispatchLocations[0]);

		if (dispatchLocations.size() < 2) {
			return;
		}

		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			clusteredLocations.add(dispatchLocation.Id);
		}
	}

	private Id id { get { return dispatchLocation.Id; } }
	private String name { get { return dispatchLocation.Location__r.Name; } }
	private Integer sortOrder { get { return Convert.toInteger(dispatchLocation.SequenceNumber__c); } }
	private Decimal latitude { get { return dispatchLocation.Location__r.BillingLatitude; } }
	private Decimal longitude { get { return dispatchLocation.Location__r.BillingLongitude; } }
	private String street { get { return dispatchLocation.Location__r.BillingStreet; } }
	private String city { get { return dispatchLocation.Location__r.BillingCity; } }
	private String postcode { get { return dispatchLocation.Location__r.BillingPostalCode; } }
	private String country { get { return dispatchLocation.Location__r.BillingCountry; } }
	private String status { get { return dispatchLocation.Status__c; } }
	private String priority { get { return dispatchLocation.Location__r.CollectionPriority__c; } }
	private String type { get { return dispatchLocation.Type__c; } }
	private Boolean isCluster { get { return clusteredLocations.size() > 1; } }
	private Boolean isBinCollection { get { return dispatchLocation.IsBinCollection__c; } }
	private Boolean isInternalCollection { get { return dispatchLocation.IsInternalCollection__c; } }
	private Boolean isSubmissionGeofenced { get { return isBinCollection || type == 'Missed' || type == 'Extra' || priority == 'VIP' || priority == 'New'; } }
	private String scheduleTime { get { return Convert.toHhMm(dispatchLocation.Time__c); } }
	private String notes { get { return dispatchLocation.Location__r.Comments_c__c; } }

	private class Item {
		private transient Collection_Waypoints__c waypoint;

		private Item(Collection_Waypoints__c waypoint) {
			this.waypoint = waypoint;
		}

		private Id id { get { return waypoint.Id; } }
		private String name { get { return waypoint.Supplier_Product_Name__c; } }
		private Boolean isBin { get { return waypoint.Is_bin_collection__c; } }
		private Integer quantity { get { return Convert.toInteger(waypoint.Collection_Quantity__c); } }
	}
}