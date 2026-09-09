trigger DeliveryPackageTrackingEventTrigger on DeliveryPackageTrackingEvent__c (after insert) {

    new DeliveryPackageTrackingEventHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}