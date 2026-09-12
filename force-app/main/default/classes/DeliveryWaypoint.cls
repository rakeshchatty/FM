public without sharing class DeliveryWaypoint {

	public void create(List<DeliveryPackage__c> packages) {
		Map<String, maps__Route__c> routes = createRoutes(packages);

		List<maps__Waypoint__c> waypoints = new List<maps__Waypoint__c>();
		for (DeliveryPackage__c pkg : packages) {
			maps__Waypoint__c waypoint = new maps__Waypoint__c();
			waypoint.maps__LinkId__c = waypoint.Order__c = pkg.Order__c;
			waypoint.maps__Route__c = routes.get(formRouteName(pkg)).Id;
			waypoints.add(waypoint);
		}
		INSERT waypoints;
	}

	private Map<String, maps__Route__c> createRoutes(List<DeliveryPackage__c> packages) {
		Set<String> routeNames = new Set<String>();
		for (DeliveryPackage__c pkg : packages) {
			routeNames.add(formRouteName(pkg));
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

	private String formRouteName(DeliveryPackage__c pkg) {
		return pkg.Carrier__c + ' - ' + pkg.RequestedDeliveryDate__c;
	}
}