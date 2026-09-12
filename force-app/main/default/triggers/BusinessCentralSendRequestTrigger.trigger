trigger BusinessCentralSendRequestTrigger on BusinessCentralSendRequest__c (after insert, after update) {

    new BusinessCentralRequestChaining().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}