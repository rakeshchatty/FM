public without sharing class DeliveryPackageTriggerHandler {

	private static final String ROUTE_PREFIX = 'Parcelforce - ';

	public void handleTrigger(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				sendShipment(newList);
				createWaypoints(newList);
			}
			when AFTER_UPDATE {
				sendShipment(newList, oldMap);
				extractLabel(newList, oldMap);
				cancelShipment(newList, oldMap);
			}
		}
	}

	private static void sendShipment(List<DeliveryPackage__c> newList) {
		sendShipment(IdUtil.extractId(newList));
	}

	private static void sendShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (pkg.Status__c == DeliveryPackage.STATUS_RETRY && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_RETRY) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			sendShipment(packageIds);
		}
	}

	private static void sendShipment(Set<Id> packageIds){
		Database.executeBatch(new DeliveryPackageShipmentBatch(packageIds), 40);
	}

	private static void extractLabel(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (pkg.Status__c == DeliveryPackage.STATUS_ADVISED && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_ADVISED) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			Database.executeBatch(new DeliveryPackageLabelBatch(packageIds), 40);	// Maximum 100 callout allowed in single transaction.
		}
	}

	private static void cancelShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (!pkg.IsFinalStatus__c && pkg.Status__c == DeliveryPackage.STATUS_CANCEL_REQUEST && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_CANCEL_REQUEST) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			Database.executeBatch(new DeliveryPackageCancellationBatch(packageIds), 40);	// Providing 3 seconds for each callout. 40*3 = 120 seconds.
		}
	}

	private void createWaypoints(List<DeliveryPackage__c> newList) {
		Map<String, maps__Route__c> routes = createRoutes(newList);

		List<maps__Waypoint__c> waypoints = new List<maps__Waypoint__c>();
		for (DeliveryPackage__c pkg : newList) {
			maps__Waypoint__c waypoint = new maps__Waypoint__c();
			waypoint.maps__LinkId__c = waypoint.Order__c = pkg.Order__c;
			waypoint.maps__Route__c = routes.get(ROUTE_PREFIX + pkg.RequestedDeliveryDate__c).Id;
			waypoints.add(waypoint);
		}
		INSERT waypoints;
	}

	private Map<String, maps__Route__c> createRoutes(List<DeliveryPackage__c> newList) {
		Set<String> routeNames = new Set<String>();
		for (DeliveryPackage__c pkg : newList) {
			routeNames.add(ROUTE_PREFIX + pkg.RequestedDeliveryDate__c);
		}

		Map<String, maps__Route__c> routes = new Map<String, maps__Route__c>();
		List<maps__Route__c> existingRoutes = [SELECT Id, Name FROM maps__Route__c WHERE Name IN :routeNames];
		for (maps__Route__c route : existingRoutes) {
			routes.put(route.Name, route);
		}

		routeNames.removeAll(routes.keySet());
		if (routeNames.isEmpty()) {
			return routes;
		}

		Map<String, maps__Route__c> newRoutes = new Map<String, maps__Route__c>();
		for(String newRouteName : routeNames) {
			newRoutes.put(newRouteName, new maps__Route__c(Name = newRouteName));
		}
		INSERT newRoutes.values();
		routes.putAll(newRoutes);
		return routes;
	}
}