trigger DeliveryOrderGroupTrigger on DeliveryOrderGroup__c (after update) {
    
new DeliveryOrderGroupTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}