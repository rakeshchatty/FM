trigger EmailActivity on Email_Activity__c (before insert) {
    EmailActivityTriggerHelper.populateContactfromEmail(Trigger.New);
}