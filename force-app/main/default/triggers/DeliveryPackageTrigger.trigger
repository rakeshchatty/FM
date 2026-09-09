trigger DeliveryPackageTrigger on DeliveryPackage__c (after insert, after update) {

	new DeliveryPackageTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}