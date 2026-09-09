trigger ReceivedWaypointGroupEventTrigger on ReceivedWaypointGroupEvent__e (after insert) {

	for (ReceivedWaypointGroupEvent__e event : Trigger.new) {
		new ReceivedWaypointGroupEventHandler(event).process();
	}
}