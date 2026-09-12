trigger HubSpotAcrSyncTrigger on HubSpotAcrSync__e (after insert) {

	for (HubSpotAcrSync__e event : trigger.new) {
		if (event.Action__c == 'UPSERT') {
			HubSpotAcrSync.upsertAssociation(event.HubSpotContactId__c, event.HubSpotAccountId__c, event.AcrId__c, event.Roles__c, event.PerformDelete__c);
		}

		if (event.Action__c == 'DELETE') {
			HubSpotAcrSync.deleteAssociation(event.HubSpotContactId__c, event.HubSpotAccountId__c, event.AcrId__c);
		}
	}
}