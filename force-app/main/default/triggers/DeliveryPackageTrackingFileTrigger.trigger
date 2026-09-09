trigger DeliveryPackageTrackingFileTrigger on DeliveryPackageTrackingFile__c (after insert,after update) {

	new DeliveryPackageTrakingFileTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}