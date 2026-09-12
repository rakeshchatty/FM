trigger ContactChangeEventTrigger on ContactChangeEvent (after insert) {

	if (!BusinessCentralSetting__c.getOrgDefaults().IsLive__c) {
		return;
	}
	new ContactChangeEventTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}