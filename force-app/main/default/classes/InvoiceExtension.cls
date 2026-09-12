public with sharing class InvoiceExtension {

	public LegalEntity__c entity { get; private set; }
	public Map<String, Map<Account, List<Invoice_Line__c>>> groupByPoNumber { get; private set; }
	public Map<Account, List<Invoice_Line__c>> groupByLocation { get; private set; }
	public Map<String, Decimal> subtotals { get; private set; }
	public String poNumber { get; private set; }
	public Boolean showPONumber { get; private set; }

	public InvoiceExtension(ApexPages.StandardController ctrl) {
		groupByPoNumber = new Map<String, Map<Account, List<Invoice_Line__c>>>();
		groupByLocation = new Map<Account, List<Invoice_Line__c>>();
		subtotals = new Map<String, Decimal>();

		Invoice_Header__c invHeader = [SELECT Account__r.OwningEntity__c, Account__r.InvoiceFrequency__c, InvoiceFrequency__c, Account__r.PO_Number__c, Account__r.AdHocPONumber__c, Account__r.IgnorePOGroupingOnInvoicePDF__c
			FROM Invoice_Header__c WHERE Id = :ctrl.getId()];
		entity = LegalEntity.get(invHeader.Account__r.OwningEntity__c);

		showPONumber = invHeader.Account__r.IgnorePOGroupingOnInvoicePDF__c;

		List<Invoice_Line__c> linesWithPoNumber = [SELECT Location_Id__c, Location_Id__r.Name, DeliveryDate__c,
			Description__c, Qty__c, UnitPrice__c, Amount__c, PO_Number__c, Location_Id__r.BillingPostalCode
			FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :ctrl.getId() AND PO_Number__c != null AND Location_Id__r.Parent.IgnorePOGroupingOnInvoicePDF__c = false
			ORDER BY Location_Id__c, DeliveryDate__c];

		List<Invoice_Line__c> linesWithoutPoNumber = [SELECT Location_Id__c, Location_Id__r.Name, DeliveryDate__c,
			Description__c, Qty__c, UnitPrice__c, Amount__c, PO_Number__c, Location_Id__r.BillingPostalCode
			FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :ctrl.getId() AND (PO_Number__c = null OR Location_Id__r.Parent.IgnorePOGroupingOnInvoicePDF__c = true)
			ORDER BY Location_Id__c, DeliveryDate__c];

		groupByPoNumber(linesWithPoNumber);
		groupByLocation(linesWithoutPoNumber);

		getPoNumber(invHeader);
	}

	private void groupByPoNumber(List<Invoice_Line__c> invoiceLines) {
		String linePoNumber;
		List<Invoice_Line__c> invoices;

		for (Invoice_Line__c invoiceLine : invoiceLines) {
			linePoNumber = invoiceLine.PO_Number__c;

			if (!groupByPoNumber.containsKey(linePoNumber)) {
				groupByPoNumber.put(linePoNumber, new Map<Account, List<Invoice_Line__c>>());
				subtotals.put(linePoNumber, 0);
			}

			invoices = groupByPoNumber.get(linePoNumber).get(invoiceLine.Location_Id__r);
			if (invoices == null) {
				invoices = new List<Invoice_Line__c>();
				groupByPoNumber.get(linePoNumber).put(invoiceLine.Location_Id__r, invoices);
			}

			invoices.add(invoiceLine);
			subtotals.put(linePoNumber, subtotals.get(linePoNumber) + invoiceLine.Amount__c);
		}
	}

	private void groupByLocation(List<Invoice_Line__c> invoiceLines) {
		List<Invoice_Line__c> invoices;

		for (Invoice_Line__c invoiceLine : invoiceLines) {
			invoices = groupByLocation.get(invoiceLine.Location_Id__r);
			if (invoices == null) {
				invoices = new List<Invoice_Line__c>();
				groupByLocation.put(invoiceLine.Location_Id__r, invoices);
				subtotals.put(invoiceLine.Location_Id__c, 0);
			}

			invoices.add(invoiceLine);
			subtotals.put(invoiceLine.Location_Id__c, subtotals.get(invoiceLine.Location_Id__c) + invoiceLine.Amount__c);
		}
	}

	private void getPoNumber(Invoice_Header__c invoiceHeader) {
		if (invoiceHeader.invoiceFrequency__c == Invoicing.FREQUENCY_MONTHLY_SCHEDULED || invoiceHeader.invoiceFrequency__c == Invoicing.FREQUENCY_ADVANCE) {
			poNumber = invoiceHeader.Account__r.PO_Number__c;
		} else if (invoiceHeader.invoiceFrequency__c == Invoicing.FREQUENCY_MONTHLY && invoiceHeader.Account__r.InvoiceFrequency__c == Invoicing.FREQUENCY_MONTHLY_SEPARATED) {
			poNumber = invoiceHeader.Account__r.AdHocPONumber__c;
		}
	}
}