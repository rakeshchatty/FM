public without sharing class CreateOrderFromExtraWaypoint {

	@InvocableMethod(label='Create Order From Waypoint')
	public static void create(List<Id> waypointIds) {
		new CreateOrderFromWaypoint(waypointIds).create();
	}
}