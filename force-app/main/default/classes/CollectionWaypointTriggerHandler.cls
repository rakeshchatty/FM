public without sharing class CollectionWaypointTriggerHandler {

	public void handleTrigger(List<Collection_Waypoints__c> newList, Map<Id, Collection_Waypoints__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_UPDATE {
				changeDispatchLocation(newList, oldMap);
				deleteEmptyDispatchLocations(newList, oldMap);
			}
		}
	}

	private List<Collection_Waypoints__c> filterDispatchChanged(List<Collection_Waypoints__c> newList, Map<Id, Collection_Waypoints__c> oldMap) {
		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();

		for (Collection_Waypoints__c waypoint : newList) {
			if (waypoint.Daily_Dispatch__c != oldMap.get(waypoint.Id).Daily_Dispatch__c) {
				waypoints.add(waypoint);
			}
		}
		return waypoints;
	}

	private void changeDispatchLocation(List<Collection_Waypoints__c> newList, Map<Id, Collection_Waypoints__c> oldMap) {
		List<Collection_Waypoints__c> waypoints = filterDispatchChanged(newList, oldMap);
		if (waypoints.isEmpty()) {
			return;
		}

		Map<String, DispatchLocation__c> dispatchLocationMap = CreateDispatchLocation.create(waypoints);
		UPSERT dispatchLocationMap.values();

		List<Collection_Waypoints__c> waypointsToUpdate = new List<Collection_Waypoints__c>();
		for (Collection_Waypoints__c waypoint : waypoints) {
			waypointsToUpdate.add(new Collection_Waypoints__c(Id = waypoint.Id, DispatchLocation__c = dispatchLocationMap.get(CreateDispatchLocation.key(waypoint)).Id));
		}

		UPDATE waypointsToUpdate;
	}

	private void deleteEmptyDispatchLocations(List<Collection_Waypoints__c> newList, Map<Id, Collection_Waypoints__c> oldMap) {
		List<Collection_Waypoints__c> waypoints = filterDispatchChanged(newList, oldMap);
		if (waypoints.isEmpty()) {
			return;
		}

		Set<Id> dispatchLocationIds = new Set<Id>();
		for (Collection_Waypoints__c waypoint : waypoints) {
			dispatchLocationIds.add(oldMap.get(waypoint.Id).DispatchLocation__c);
		}

		List<DispatchLocation__c> dispatchLocationsToDelete = new List<DispatchLocation__c>();
		List<DispatchLocation__c> dispatchLocations = [SELECT Id, (SELECT Id FROM CollectionWaypoints__r LIMIT 1) FROM DispatchLocation__c WHERE Id IN :dispatchLocationIds];
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			if (dispatchLocation.CollectionWaypoints__r.isEmpty()) {
				dispatchLocationsToDelete.add(dispatchLocation);
			}
		}

		DELETE dispatchLocationsToDelete;
	}
}