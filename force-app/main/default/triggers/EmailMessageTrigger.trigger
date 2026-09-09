trigger EmailMessageTrigger on EmailMessage (before insert) {
	new EmailMessageTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}