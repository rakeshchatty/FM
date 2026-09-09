public with sharing class InvoiceDocRedirectExtension {

	Id invoiceId;

	public InvoiceDocRedirectExtension(Invoice_Header__c invoice) {
		invoiceId = invoice.Id;
	}

	public InvoiceDocRedirectExtension(ApexPages.StandardController controller) {
		invoiceId = controller.getId();
	}

	public PageReference redirect() {
		Invoice_Header__c invoiceHeader = [SELECT InvoiceFrequency__c FROM Invoice_Header__c WHERE Id = :invoiceId];
		if (invoiceHeader.InvoiceFrequency__c == Invoicing.FREQUENCY_IMMEDIATE) {
			return new PageReference('/apex/InvoiceDocumentPdf?id=' + invoiceId);
		} else {
			return new PageReference('/apex/InvoiceMonthPdf?id=' + invoiceId);
		}
	}
}