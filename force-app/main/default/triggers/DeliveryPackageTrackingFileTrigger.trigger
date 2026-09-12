trigger DeliveryPackageTrackingFileTrigger on DeliveryPackageTrackingFile__c (after insert) {

	new DeliveryPackageTrackingFileHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}