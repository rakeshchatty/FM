trigger AccountDiscountTrigger on Account_Discount__c (before insert) {
    if(Trigger.IsInsert && Trigger.IsBefore) {
        AccountDiscountTriggerHandler.handleBeforeInsert(Trigger.New);
    }
}