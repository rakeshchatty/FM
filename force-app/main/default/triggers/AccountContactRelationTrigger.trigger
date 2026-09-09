trigger AccountContactRelationTrigger on AccountContactRelation (after insert, after update, before delete) {

	new AccountContactRelationTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}