public class SageExtractFromInvoiceBatch implements Database.Batchable<sObject> {

	private final static String statusClosed = Invoicing.STATUS_CLOSED;

	private Date dueDate;

	public SageExtractFromInvoiceBatch() {
		this.dueDate = System.today() - 1;
	}

	public SageExtractFromInvoiceBatch(Date someDate) {
		this.dueDate = someDate;
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		String query = 'SELECT Product__r.Nl_accode__c, Product_AccCode__c, Amount__c, VAT__c, Invoice_HeaderId__c, Invoice_HeaderId__r.DueDate__c FROM Invoice_Line__c WHERE SageExtractCreated__c = false AND Invoice_HeaderId__r.Status__c = :statusClosed AND Invoice_HeaderId__r.DueDate__c = :dueDate ORDER BY Invoice_HeaderId__c';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<Invoice_Line__c> invoiceLines) {
		List <SageExtract__c> sageLines = new List <SageExtract__c>();
		for (Invoice_Line__c invoiceLine : invoiceLines) {
			sageLines.addAll(Sage.createLines(invoiceLine));
		}

		Database.insert(sageLines, false);
		Database.update(invoiceLines, false);
	}

	public void finish(Database.BatchableContext batchContext) {
		List<Invoice_Header__c> invoices = [SELECT Id FROM Invoice_Header__c WHERE SageExtractCreated__c = false AND Status__c = :statusClosed AND DueDate__c = YESTERDAY];
		for (Invoice_Header__c invoice : invoices) {
			invoice.SageExtractCreated__c = true;
			invoice.Ready_to_Email__c = true;
		}

		Database.update(invoices, false);
	}
}