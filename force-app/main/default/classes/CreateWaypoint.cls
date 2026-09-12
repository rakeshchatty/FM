public without sharing class CreateWaypoint {

	public static void create(List<Missed_Collection__c> missedCollections) {
		insertWaypoint(createWaypoint(missedCollections));
	}

	public static void create(List<Case> cases) {
		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();
		List<Collection_Waypoints__c> extraWaypoints = new List<Collection_Waypoints__c>();

		for (Case waypointCase : cases) {
			Collection_Waypoints__c waypoint = createWaypoint(waypointCase, waypointCase.Round_Dispatched__r);
			waypoint.Supplier__c = waypointCase.Supplier__c;
			waypoint.Supplier_Product__c = waypointCase.SupplierProduct__c;
			waypoint.Collection_Quantity__c = waypointCase.Quantity__c > 1 ? waypointCase.Quantity__c : 1;
			if (waypointCase.ManualPrice__c != null) {
				waypoint.Manual_Price__c = waypointCase.ManualPrice__c;
				waypoint.Discount_Type__c = '';
			}
			waypoint.SupplierUnitPrice__c = waypointCase.SupplierUnitPrice__c;
			waypoints.add(waypoint);
			if (waypointCase.Type == 'Extra Job') {
				extraWaypoints.add(waypoint);
			}
		}

		applyDiscount(extraWaypoints);
		insertWaypoint(waypoints);
	}

	private static Collection_Waypoints__c createWaypoint(Case waypointCase, DailyDispatch__c dispatchAllocated) {
		return new Collection_Waypoints__c(Name = waypointCase.Type + ' - ' + waypointCase.AccountId, Case__c = waypointCase.Id,
			Daily_Dispatch__c = dispatchAllocated.Id, Location__c = waypointCase.AccountId);
	}

	private static List<Collection_Waypoints__c> createWaypoint(List<Missed_Collection__c> missedCollections) {
		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();

		for (Missed_Collection__c missedCollection : missedCollections) {
			Collection_Waypoints__c waypoint = createWaypoint(missedCollection.Case__r, missedCollection.DispatchAllocated__r);
			waypoint.MissedCollection__c = missedCollection.Id;

			Schedule__c schedule = missedCollection.Collection_Schedule__r;
			waypoint.Name = schedule.Name;
			waypoint.Collection_Schedule__c = schedule.Id;
			waypoint.Is_bin_collection__c = schedule.Is_bin_collection__c;
			waypoint.Collection_Quantity__c = schedule.Collection_Quantity__c;
			waypoint.Supplier__c = schedule.Supplier__c;
			waypoint.Supplier_Product__c = schedule.Supplier_Product__c;
			waypoints.add(waypoint);
		}

		return waypoints;
	}

	private static void applyDiscount(List<Collection_Waypoints__c> waypoints) {
		Set<Id> locationIds = new Set<Id>();
		Set<Id> supplierProductsIds = new Set<Id>();
		for (Collection_Waypoints__c waypoint : waypoints) {
			locationIds.add(waypoint.Location__c);
			supplierProductsIds.add(waypoint.Supplier_Product__c);
		}
		Map<Id, Account> locations = new Map<Id, Account>([SELECT Id, ParentId, Partnership__c FROM Account WHERE Id IN :locationIds]);

		Set<Id> parentIds = new Set<Id>();
		Set<Id> partnerIds = new Set<Id>();
		Account location;
		for (Collection_Waypoints__c waypoint : waypoints) {
			location = locations.get(waypoint.Location__c);
			parentIds.add(location.ParentId);
			partnerIds.add(location.Partnership__c);
		}

		Map<Id, Supplier_Product__c> supplierProducts = new Map<Id, Supplier_Product__c>([SELECT Id, Product__c FROM Supplier_Product__c WHERE Id IN :supplierProductsIds]);
		Set<Id> productsIds = new Set<Id>();
		for (Supplier_Product__c supplierProduct : supplierProducts.values()) {
			productsIds.add(supplierProduct.Product__c);
		}

		Map<String, Account_Discount__c> parentDiscounts = AccountUtil.getDiscounts(parentIds, productsIds);
		Map<String, Account_Discount__c> partnerDiscounts = AccountUtil.getDiscounts(partnerIds, productsIds);

		Account_Discount__c parentDiscount;
		Account_Discount__c partnerDiscount;
		Supplier_Product__c supplierProduct;
		for (Collection_Waypoints__c waypoint : waypoints) {
			location = locations.get(waypoint.Location__c);
			supplierProduct = supplierProducts.get(waypoint.Supplier_Product__c);
			parentDiscount = parentDiscounts.get(location.ParentId + '-' + supplierProduct.Product__c);
			partnerDiscount = partnerDiscounts.get(location.Partnership__c + '-' + supplierProduct.Product__c);
			if (parentDiscount == null && partnerDiscount == null) {
				continue;
			} else if (parentDiscount == null) {
				waypoint.Discount_Type__c = 'Partner';
				waypoint.Account_Discount__c = partnerDiscount.Id;
			} else if (partnerDiscount == null) {
				waypoint.Discount_Type__c = 'Account';
				waypoint.Account_Discount__c = parentDiscount.Id;
			} else {
				if (parentDiscount.Product_Discount__c > (partnerDiscount.Product_Discount__c + (partnerDiscount.BID_Price__c ?? 0))) {
					waypoint.Discount_Type__c = 'Account';
					waypoint.Account_Discount__c = parentDiscount.Id;
				} else {
					waypoint.Discount_Type__c = 'Partner';
					waypoint.Account_Discount__c = partnerDiscount.Id;
				}
			}
		}
	}

	private static void insertWaypoint(List<Collection_Waypoints__c> waypoints) {
		INSERT waypoints;

		Map<String, DispatchLocation__c> dispatchLocationMap = CreateDispatchLocation.create(waypoints);
		UPSERT dispatchLocationMap.values();	// Contains a combination of existing and newly created Dispatch Locations

		List<Missed_Collection__c> missedCollections = new List<Missed_Collection__c>();
		for (Collection_Waypoints__c waypoint : waypoints) {
			waypoint.DispatchLocation__c = dispatchLocationMap.get(CreateDispatchLocation.key(waypoint)).Id;

			if (waypoint.MissedCollection__c != null) {
				missedCollections.add(new Missed_Collection__c(Id = waypoint.MissedCollection__c, CollectionWaypoint__c = waypoint.Id));
			}
		}
		UPDATE waypoints;
		UPDATE missedCollections;
	}
}