public class DeliveryOrderGroupTriggerHandler {
    
    public void handleTrigger(List<DeliveryOrderGroup__c> newList, Map<Id, DeliveryOrderGroup__c> oldMap, TriggerOperation operation) {
        switch on operation {
            when AFTER_UPDATE {
                processUpdate(newList, oldMap);				
            }
        }
    }

    public static void processUpdate(List<DeliveryOrderGroup__c> newList, Map<Id, DeliveryOrderGroup__c> oldMap) {
        List<Id> beforeRequestIds = new List<Id>();
        List<Id> afterRequestIds = new List<Id>();
        for (DeliveryOrderGroup__c deliveryOrderGroup: newList) {
            DeliveryOrderGroup__c oldRecord = oldMap.get(deliveryOrderGroup.Id);
            if (deliveryOrderGroup.Status__c == 'Requested' && oldRecord.Status__c != 'Requested') {
                beforeRequestIds.add(deliveryOrderGroup.Id);
                DeliveryRouting.prepareRequest(deliveryOrderGroup.Id);
            } else if (deliveryOrderGroup.Status__c == 'Sequence Completed' && oldRecord.Status__c != 'Sequence Completed') {
                afterRequestIds.add(deliveryOrderGroup.Id);
                processSequenceCompletion(deliveryOrderGroup);
            }                    
        }
    }
    
    public static void processSequenceCompletion(DeliveryOrderGroup__c deliveryOrderGroup) {
        List<DeliveryOrder__c> deliveryOrders = [SELECT Order__c, Order__r.Id, DeliveryRoute__r.Name, SequenceNumber__c, RouteDate__c FROM DeliveryOrder__c WHERE DeliveryOrderGroup__c = :deliveryOrderGroup.Id];
        List<ReceivedWaypoint__c> receivedWaypoints = new List<ReceivedWaypoint__c>();
        for (DeliveryOrder__c deliveryOrder : deliveryOrders) {
            ReceivedWaypoint__c receivedWaypoint = new ReceivedWaypoint__c();
            receivedWaypoint.Name = deliveryOrder.DeliveryRoute__r.Name;
            receivedWaypoint.Timestamp__c = deliveryOrderGroup.Id;
            receivedWaypoint.Status__c = 'New';
            receivedWaypoint.SequenceNumber__c = deliveryOrder.SequenceNumber__c;
            receivedWaypoint.Order__c = deliveryOrder.Order__r.Id;
            receivedWaypoint.Source__c = 'Raas';
            receivedWaypoint.Date__c = Date.today().addDays(1);
            receivedWaypoints.add(receivedWaypoint);            
        }
        INSERT receivedWaypoints; 
        
        ReceivedWaypointGroup__c receivedWaypointGroup = new ReceivedWaypointGroup__c();
        receivedWaypointGroup.Date__c = Date.today().addDays(1);        
        receivedWaypointGroup.Source__c = 'Raas';
        receivedWaypointGroup.Status__c = 'New';
        receivedWaypointGroup.Timestamp__c = deliveryOrderGroup.Id;
        INSERT receivedWaypointGroup;
    }
}