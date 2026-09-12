public without sharing class SeasonTicketWtnRenewalBatch implements Database.Batchable<sObject>, Database.Stateful {

	private List<String> wtnIds = new List<String>();

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([SELECT Account__c, Contractor__c FROM Compliance_Doc__c WHERE IsWTNRenewalDue__c = true AND IsAccountLive__c = true]);
	}

	public void execute(Database.BatchableContext bc, List<Compliance_Doc__c> scope) {
		for (Compliance_Doc__c wtn : scope) {
			Map<String, Object> params = new Map<String, Object>();
			params.put('LocationId', wtn.Account__c);
			params.put('SupplierId', wtn.Contractor__c);

			Flow.Interview.CreateSeasonTicketWasteTransferNotePerLocation renewalWtn = new Flow.Interview.CreateSeasonTicketWasteTransferNotePerLocation(params);
			renewalWtn.start();
			if (renewalWtn.ComplianceDocumentIds != null) {
				wtnIds.addAll(renewalWtn.ComplianceDocumentIds);
			}
		}
	}

	public void finish(Database.BatchableContext bc) {
		System.enqueueJob(new WtnWasteCategorySummaryQueuable(wtnIds));
	}
}