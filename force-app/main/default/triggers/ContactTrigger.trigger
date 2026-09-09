trigger ContactTrigger on Contact (before insert, before update, after insert, after update, before delete) {
    
    new ContactTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
    //ContactTriggerHelper.checkDuplicates(Trigger.New);
    if (Trigger.Isbefore && Trigger.IsUpdate) {
        ContactTriggerHelper.populatePreviousEmail(Trigger.New, Trigger.oldMap);
    }
    if((Trigger.IsAfter && (Trigger.IsInsert || Trigger.IsUpdate)) || (Trigger.Isbefore && Trigger.IsDelete))
    {
        ContactTriggerHelper.syncContactsToSendGrid(Trigger.New, Trigger.Old, Trigger.oldMap);
    }
}