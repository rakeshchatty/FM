trigger InvoiceChangeEventTrigger on Invoice_Header__ChangeEvent(after insert) {

	if (!BusinessCentralSetting__c.getOrgDefaults().IsLive__c) {
		return;
	}
	new InvoiceChangeEventTriggerHandler().handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);
}