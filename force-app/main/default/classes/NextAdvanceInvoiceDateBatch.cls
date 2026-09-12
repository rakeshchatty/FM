public without sharing class NextAdvanceInvoiceDateBatch implements Database.Batchable<sObject> {

	private final Date INVOICE_DATE;

	public NextAdvanceInvoiceDateBatch() {}

	public NextAdvanceInvoiceDateBatch(Date invoiceDate) {
		INVOICE_DATE = invoiceDate;
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT Id, MonthsInvoicedInAdvance__c FROM Account WHERE IsLive__c = true AND NextAdvanceInvoiceDate__c = :INVOICE_DATE AND MonthsInvoicedInAdvance__c != null]);
	}

	public void execute(Database.BatchableContext batchContext, List<Account> parents) {
		for (Account parent : parents) {
			parent.NextAdvanceInvoiceDate__c = INVOICE_DATE.addMonths(Integer.valueOf(parent.MonthsInvoicedInAdvance__c));
		}

		Database.SaveResult[] results = Database.update(parents, false);
		LogRegister.createLogsUpsert(results, parents, 'Set NextAdvanceInvoiceDate on Account', 'Update', 'Account', null);
	}

	public void finish(Database.BatchableContext batchContext) {}
}