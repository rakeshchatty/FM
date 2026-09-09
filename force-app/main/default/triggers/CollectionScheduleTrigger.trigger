trigger CollectionScheduleTrigger on Schedule__c(before insert, before update, before delete, after insert, after update) {

	new CollectionScheduleTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}