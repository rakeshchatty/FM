trigger DeliveryOrderTrigger on DeliveryOrder__c (before update) {

    if (Trigger.isUpdate && Trigger.isBefore) {
        for(DeliveryOrder__c deliveryOrder : trigger.new) {
            // new DeliveryOrderTriggerHandler().beforeUpdate(Trigger.new);
        }
    }
}