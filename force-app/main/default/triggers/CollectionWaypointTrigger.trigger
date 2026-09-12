trigger CollectionWaypointTrigger on Collection_Waypoints__c (after update) {

	new CollectionWaypointTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}