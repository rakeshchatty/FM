trigger AccountChangeEventTrigger on AccountChangeEvent(after insert) {

	if (!BusinessCentralSetting__c.getOrgDefaults().IsLive__c) {
		return;
	}
	new AccountChangeEventTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}