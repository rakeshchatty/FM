trigger AttachmentTrigger on Attachment (after insert, before delete) {

	if (Trigger.isAfter && Trigger.isInsert) {
		AttachmentHandler.afterInsertOrDeleteEvent(Trigger.New);
	}

	if (Trigger.isBefore && Trigger.isDelete) {
		AttachmentHandler.afterInsertOrDeleteEvent(Trigger.Old);
	}
}