public class InvoiceClosureBatch implements Database.Batchable<sObject> {

	private Date dueDate;

	public InvoiceClosureBatch() {
		this.dueDate = System.today() - 1;
	}

	public InvoiceClosureBatch(Date someDate) {
		this.dueDate = someDate;
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		String statusOpen = Invoicing.STATUS_OPEN;
		String query = 'SELECT Id FROM Invoice_Header__c WHERE Status__c = :statusOpen AND DueDate__c = :dueDate ORDER BY Account__c';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<Invoice_Header__c> invoices) {
		for (Invoice_Header__c invoice : invoices) {
			invoice.Status__c = Invoicing.STATUS_CLOSED;
		}

		Database.update(invoices, false);
	}

	public void finish(Database.BatchableContext batchContext) {
		Database.executeBatch(new SageExtractFromInvoiceBatch(dueDate), 200);
	}
}