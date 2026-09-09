@SuppressWarnings('PMD.ApexSharingViolations, PMD.ApexCRUDViolation')
public class ReceivedWaypointGroupEventHandler {

	/*
	Variations:
	1.	Group insertion for first time for a specific date & source combination
	2.	Add route
	3.	Delete route
	4.	New waypoint added to existing route
	5.	Delete waypoint from existing route
	6.	Route changed: i.e., Waypoint moved to another route
	7.	Sequence number of waypoint changed
	*/

	private ReceivedWaypointGroupEvent__e event;
	private Map<String, Id> mapsRoutes = new Map<String, Id>();

	public ReceivedWaypointGroupEventHandler(ReceivedWaypointGroupEvent__e event) {
		this.event = event;
	}

	public void process() {
		// Fetch all waypoints of current group to be processed
		List<ReceivedWaypoint__c> newWaypoints = [SELECT Name, Order__c, Date__c, SequenceNumber__c FROM ReceivedWaypoint__c
			WHERE Date__c = :event.Date__c AND Timestamp__c = :event.Timestamp__c AND Source__c = :event.Source__c AND Status__c = 'New'];

		Map<Id, ReceivedWaypoint__c> newOrderMap = new Map<Id, ReceivedWaypoint__c>();
		Set<String> newRouteNames = new Set<String>();
		for (ReceivedWaypoint__c receivedWaypoint : newWaypoints) {
			newOrderMap.put(receivedWaypoint.Order__c, receivedWaypoint);
			newRouteNames.add(receivedWaypoint.Name);
		}

		// Check if waypoints was received for date & source previously. Get latest group processed previously.
		List<ReceivedWaypointGroup__c> oldGroup = [SELECT Id FROM ReceivedWaypointGroup__c
			WHERE Id != :event.GroupId__c AND Date__c = :event.Date__c AND Source__c = :event.Source__c AND Status__c = 'Complete'
			ORDER BY CreatedDate DESC LIMIT 1];

		// Variation 1
		if (oldGroup.isEmpty()) {
			createMapsRoutes(newRouteNames);
			Map<Id, maps__Waypoint__c> mapsWaypointsInserted = createMapsWaypoints(newWaypoints);
			setWaypointsAsProcessed(newWaypoints, mapsWaypointsInserted, null);
			setGroupAsProcessed();
			return;
		}

		// Variation 2 to 7
		// Fetch all waypoints of latest group processed previously
		List<ReceivedWaypoint__c> oldWaypoints = [SELECT Name, Order__c, Date__c, SequenceNumber__c, MapsWaypointId__c, MapsRouteId__c FROM ReceivedWaypoint__c
				WHERE Group__c = :oldGroup[0].Id];

		Map<Id, ReceivedWaypoint__c> oldOrderMap = new Map<Id, ReceivedWaypoint__c>();
		Map<String, Id> oldRouteMap = new Map<String, Id>();
		if (!oldWaypoints.isEmpty()) {
			for (ReceivedWaypoint__c receivedWaypoint : oldWaypoints) {
				oldOrderMap.put(receivedWaypoint.Order__c, receivedWaypoint);
				oldRouteMap.put(receivedWaypoint.Name, receivedWaypoint.MapsRouteId__c);
			}
		}

		processRoutes(oldRouteMap, newRouteNames);
		processWaypoints(oldOrderMap, newOrderMap, oldRouteMap);
	}

	private void createMapsRoutes(Set<String> routesToCreate) {
		List<maps__Route__c> mapsRoutesToBeInserted = new List<maps__Route__c>();
		for (String routeName : routesToCreate) {
			mapsRoutesToBeInserted.add(new maps__Route__c(Name = routeName, maps__Date__c = event.Date__c));
		}

		INSERT mapsRoutesToBeInserted;

		for (maps__Route__c mapsRoute : mapsRoutesToBeInserted) {
			mapsRoutes.put(mapsRoute.Name, mapsRoute.Id);
		}
	}

	private Map<Id, maps__Waypoint__c> createMapsWaypoints(List<ReceivedWaypoint__c> waypointsToCreate) {
		Map<Id, maps__Waypoint__c> mapsWaypointsToBeInserted = new Map<Id, maps__Waypoint__c>();
		for (ReceivedWaypoint__c receivedWaypoint : waypointsToCreate) {
			mapsWaypointsToBeInserted.put(receivedWaypoint.Order__c, createMapsWaypoint(receivedWaypoint));
		}

		INSERT mapsWaypointsToBeInserted.values();
		return mapsWaypointsToBeInserted;
	}

	private maps__Waypoint__c createMapsWaypoint(ReceivedWaypoint__c receivedWaypoint) {
		maps__Waypoint__c mapsWaypoint = new maps__Waypoint__c();
		mapsWaypoint.maps__LinkId__c = mapsWaypoint.Order__c = receivedWaypoint.Order__c;
		mapsWaypoint.maps__SortOrder__c = receivedWaypoint.SequenceNumber__c;
		mapsWaypoint.maps__Route__c = mapsRoutes.get(receivedWaypoint.Name);
		return mapsWaypoint;
	}

	private void processRoutes(Map<String, Id> oldRouteMap, Set<String> newRouteNames) {
		// Reset isCompleted field for oldRoutes
		setRoutesAsComplete(false, oldRouteMap.values());

		// Delete
		Set<String> routesToBeDeleted = new Set<String>(oldRouteMap.keySet());
		routesToBeDeleted.removeAll(newRouteNames);
		if (!routesToBeDeleted.isEmpty()) {
			Set<Id> mapRouteIds = new Set<Id>();
			for (String routeName : routesToBeDeleted) {
				mapRouteIds.add(oldRouteMap.get(routeName));
			}
			DELETE [SELECT Id FROM maps__Route__c WHERE Id IN :mapRouteIds];
		}

		// Insert
		Set<String> routesToBeInserted = new Set<String>(newRouteNames);
		routesToBeInserted.removeAll(oldRouteMap.keySet());
		if (!routesToBeInserted.isEmpty()) {
			createMapsRoutes(routesToBeInserted);
		}

		// Retain
		Set<String> routesToBeRetained = new Set<String>(oldRouteMap.keySet());
		routesToBeRetained.removeAll(routesToBeDeleted);
		if (!routesToBeRetained.isEmpty()) {
			for (String routeName : routesToBeRetained) {
				mapsRoutes.put(routeName, oldRouteMap.get(routeName));
			}
		}
	}

	private void processWaypoints(Map<Id, ReceivedWaypoint__c> oldOrderMap, Map<Id, ReceivedWaypoint__c> newOrderMap, Map<String, Id> oldRouteMap) {
		// Delete
		Set<Id> ordersToBeDeleted  = new Set<Id>(oldOrderMap.keySet());
		ordersToBeDeleted.removeAll(newOrderMap.keySet());
		Set<Id> mapsWaypointsToBeDeleted = new Set<Id>();
		for (Id orderId : ordersToBeDeleted) {
			mapsWaypointsToBeDeleted.add(oldOrderMap.get(orderId).MapsWaypointId__c);
		}
		
		Set<Id> ordersToBeReset = new Set<Id>(ordersToBeDeleted);

		// Insert
		Map<Id, maps__Waypoint__c> mapsWaypointsToBeInserted = new Map<Id, maps__Waypoint__c>();
		Set<Id> ordersTobeInserted = new Set<Id>(newOrderMap.keySet());
		ordersTobeInserted.removeAll(oldOrderMap.keySet());
		for (String orderId : ordersTobeInserted) {
			mapsWaypointsToBeInserted.put(orderId, createMapsWaypoint(newOrderMap.get(orderId)));
		}

		// Retain
		Set<Id> ordersToBeRetained = new Set<Id>(oldOrderMap.keySet());
		ordersToBeRetained.removeAll(ordersToBeDeleted);
		for (String orderId : ordersToBeRetained) {
			ReceivedWaypoint__c oldReceivedWaypoint = oldOrderMap.get(orderId);
			ReceivedWaypoint__c newReceivedWaypoint = newOrderMap.get(orderId);
			if (newReceivedWaypoint.Name != oldReceivedWaypoint.Name || newReceivedWaypoint.SequenceNumber__c != oldReceivedWaypoint.SequenceNumber__c) {
				ordersToBeReset.add(orderId);
				mapsWaypointsToBeDeleted.add(oldReceivedWaypoint.MapsWaypointId__c);
				mapsWaypointsToBeInserted.put(newReceivedWaypoint.Order__c, createMapsWaypoint(newReceivedWaypoint));
			}
		}
		resetOrders(ordersToBeReset);

		if (!mapsWaypointsToBeDeleted.isEmpty()) {
			DELETE [SELECT Id FROM maps__Waypoint__c WHERE Id IN :mapsWaypointsToBeDeleted];
		}

		if (!mapsWaypointsToBeInserted.isEmpty()) {
			INSERT mapsWaypointsToBeInserted.values();
		}

		setWaypointsAsProcessed(newOrderMap.values(), mapsWaypointsToBeInserted, oldOrderMap);
		setGroupAsProcessed();
	}

	private void setWaypointsAsProcessed(List<ReceivedWaypoint__c> receivedWaypoints, Map<Id, maps__Waypoint__c> mapsWaypointsInserted, Map<Id, ReceivedWaypoint__c> oldOrderMap) {
		for (ReceivedWaypoint__c receivedWaypoint : receivedWaypoints) {
			receivedWaypoint.Status__c = 'Complete';
			receivedWaypoint.Group__c = event.GroupId__c;
			receivedWaypoint.MapsWaypointId__c = mapsWaypointsInserted.containsKey(receivedWaypoint.Order__c) ? mapsWaypointsInserted.get(receivedWaypoint.Order__c).Id : oldOrderMap.get(receivedWaypoint.Order__c).MapsWaypointId__c;
			receivedWaypoint.MapsRouteId__c = mapsRoutes.get(receivedWaypoint.Name);
		}
		UPDATE receivedWaypoints;
	}

	private void resetOrders(Set<Id> orderIds) {
		List<Order> orders = new List<Order>();
		for (Id orderId : orderIds) {
			Order order = new order(Id = orderId, Detrack_Status__c = 'In progress', Delivery_Status__c = 'Awaiting Allocation');
			order.Maps_Route__c = order.RouteName__c = order.Tracking_Link__c = null;
			orders.add(order);
		}
		UPDATE orders;
	}

	private void setGroupAsProcessed() {
		UPDATE new ReceivedWaypointGroup__c(Id = event.GroupId__c, Status__c = 'Complete');
		setRoutesAsComplete(true, mapsRoutes.values());
	}

	private void setRoutesAsComplete(Boolean isComplete, List<Id> mapsRouteIds) {
		List<maps__Route__c> routes = new List<maps__Route__c>();
		for (Id routeId : mapsRouteIds) {
			routes.add(new maps__Route__c(Id = routeId, IsComplete__c = isComplete));
		}
		UPDATE routes;
	}
}