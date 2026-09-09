trigger AccountOperationTrigger on Account (after update) 
{
    if(Trigger.IsAfter && Trigger.IsUpdate)
    {
        AccountOperationTriggerHelper.syncSendgridContacts(Trigger.New, Trigger.Old, Trigger.newMap, Trigger.oldMap);
    }
}