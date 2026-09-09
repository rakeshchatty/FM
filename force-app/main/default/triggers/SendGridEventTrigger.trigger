trigger SendGridEventTrigger on SendGridEvent__e (after insert) {

	Integer counter = 0;
	for (SendGridEvent__e event : Trigger.new) {
		new SendGridEmail().send(event);
		EventBus.TriggerContext.currentContext().setResumeCheckpoint(event.ReplayId);

		if (++counter == 50) { // Maximum 50 future calls allowed in single transaction.
			break;
		}
	}
}