trigger WeightTrigger on Weight__c (after insert, after update, after delete) {

	new WeightTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}