trigger NoteTrigger on Note (after insert, before delete) {

	if (Trigger.isInsert && Trigger.isAfter) {
		NoteTriggerHandler.afterInsertOrDeleteEvent(Trigger.New);
	}

	if (Trigger.isDelete && Trigger.isbefore) {
		NoteTriggerHandler.afterInsertOrDeleteEvent(Trigger.Old);
	}
}