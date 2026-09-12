trigger PaymentChangeEventTrigger on Bank_Statement__ChangeEvent (after insert) {

	if (!BusinessCentralSetting__c.getOrgDefaults().IsLive__c) {
		return;
	}
	new PaymentChangeEventTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}