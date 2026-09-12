trigger DeliveryPackageQrCode on DeliveryPackageQrCode__c (before insert, after insert) {

	new DeliveryPackageQrCodeHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}