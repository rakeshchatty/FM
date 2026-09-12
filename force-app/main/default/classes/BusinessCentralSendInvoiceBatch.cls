public without sharing class BusinessCentralSendInvoiceBatch implements Database.Batchable<sObject>, Database.Stateful {

	private final Integer MAX_LINES = Test.isRunningTest() ? 1 : 3000;

	private BusinessCentralRequestChaining requestChaining;
	private Map<String, Id> objectToRequestMap;

	public BusinessCentralSendInvoiceBatch(BusinessCentralRequestChaining requestChaining) {
		this.requestChaining = requestChaining;
		this.objectToRequestMap = requestChaining.getRequests(BusinessCentralRequestChaining.ENTITY_INVOICE);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		Set<String> invoceIds = objectToRequestMap.keySet();
		String query = 'SELECT Id, BusinessCentralId__c, InvoiceNo2__c, DueDate__c, Account__c, InvoiceFrequency__c, ' +
			'Account__r.PO_Number__c, Account__r.CP_Account_Code__c, Original_Invoice_to_Credit__c, Original_Invoice_to_Credit__r.InvoiceNo2__c, ' +
			'Original_Invoice_to_Credit__r.AmountOutstanding__c, VAT__c, AmountInclVAT_f__c, InvoicePaymentMethod__c, LineCount__c, CurrencyIsoCode, ' +
			'(SELECT Id, NominalCode__c, Description__c, Qty__c, UnitPrice__c, DeliveryDate__c, Order__r.OrderNumber, ' +
				'Order__r.PO_Number__c, Location_Id__r.PO_Number__c, Location_Id__c, Order__c, Payment__r.BusinessCentralId__c FROM Invoice_Lines__r) ' +
			'FROM Invoice_Header__c WHERE Id IN :invoceIds';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Invoice_Header__c> scope) {
		if (scope.size() > 1) {
			throw new IllegalArgumentException('Cannot execute batch with size more than 1.');
		}

		Invoice_Header__c invoice = scope[0];
		if (Invoicing.isCredit(invoice)) {
			System.enqueueJob(new BusinessCentralSendInvoiceQueue(prepareCreditNote(invoice), objectToRequestMap.get(invoice.Id)));
		} else {
			System.enqueueJob(new BusinessCentralSendInvoiceQueue(prepareInvoice(invoice), objectToRequestMap.get(invoice.Id)));
		}
	}

	private List<BusinessCentralInvoice> prepareInvoice(Invoice_Header__c invoice) {
		List<BusinessCentralInvoice> bcInvoices = new List<BusinessCentralInvoice>();
		BusinessCentralInvoice bcInvoice = new BusinessCentralInvoice();
		bcInvoice.documentNumber = StringUtil.abbreviate(invoice.InvoiceNo2__c, 20);
		bcInvoice.salesforceId = invoice.Id;
		bcInvoice.postingDate = invoice.DueDate__c;
		bcInvoice.sellToCustomerNo = invoice.Account__c;
		bcInvoice.cpAccountCode = invoice.Account__r.CP_Account_Code__c;
		bcInvoice.frequency = invoice.InvoiceFrequency__c;
		bcInvoice.externalDocumentNumber = StringUtil.abbreviate(invoice.Account__r.PO_Number__c, 35);
		bcInvoice.dueDate = invoice.DueDate__c;
		bcInvoice.vat = invoice.VAT__c;
		bcInvoice.amountInclVAT = invoice.AmountInclVAT_f__c;
		bcInvoice.paymentMethodCode = PaymentUtil.transformPaymentMethodCode(invoice.InvoicePaymentMethod__c);
		bcInvoice.currencyCode = invoice.CurrencyIsoCode == 'GBP' ? null : invoice.CurrencyIsoCode;
		bcInvoice.lineCount = Integer.valueOf(invoice.LineCount__c);

		List<BusinessCentralInvoice.FMsalesInvoiceLines> bcLines = new List<BusinessCentralInvoice.FMsalesInvoiceLines>();
		Integer lineCount = 0;
		for (Invoice_Line__c line : invoice.Invoice_Lines__r) {
			BusinessCentralInvoice.FMsalesInvoiceLines bcLine = new BusinessCentralInvoice.FMsalesInvoiceLines();
			bcLine.number_X = line.NominalCode__c;
			bcLine.salesforceId = line.Id;
			bcLine.productDescription = line.Description__c;
			bcLine.quantity = line.Qty__c;
			bcLine.unitPrice = line.UnitPrice__c;
			bcLine.shipmentDate = line.DeliveryDate__c;
			bcLine.externalDocumentNumber = (line.Order__r.PO_Number__c ?? line.Location_Id__r.PO_Number__c)?.abbreviate(35);
			bcLine.sellToCustomerNumber = line.Location_Id__c;
			bcLine.orderNumber = line.Order__r.OrderNumber;
			bcLine.paymentId = line.Payment__r?.BusinessCentralId__c;

			bcLines.add(bcLine);
			lineCount++;
			if (lineCount == invoice.LineCount__c || bcLines.size() == MAX_LINES) {
				BusinessCentralInvoice bcInvoiceClone = new BusinessCentralInvoice(bcInvoice);
				bcInvoiceClone.fMsalesInvoiceLines.addAll(bcLines);
				bcInvoices.add(bcInvoiceClone);
				bcLines.clear();
			}
		}
		return bcInvoices;
	}

	private BusinessCentralCreditNote prepareCreditNote(Invoice_Header__c invoice) {
		BusinessCentralCreditNote bcInvoice = new BusinessCentralCreditNote();
		bcInvoice.documentType = 'Credit Memo';
		bcInvoice.documentNumber = StringUtil.abbreviate(invoice.InvoiceNo2__c, 20);
		bcInvoice.salesforceId = invoice.Id;
		bcInvoice.postingDate = invoice.DueDate__c;
		bcInvoice.sellToCustomerNo = invoice.Account__c;
		bcInvoice.billToCustomerNumber = invoice.Account__c;
		bcInvoice.cpAccountCode = invoice.Account__r.CP_Account_Code__c;
		bcInvoice.frequency = invoice.InvoiceFrequency__c;
		bcInvoice.externalDocumentNumber = invoice.Account__r.PO_Number__c?.abbreviate(35);
		if (invoice.Original_Invoice_to_Credit__r.AmountOutstanding__c > 0) {
			bcInvoice.appliesToDocumentType = 'Invoice';
			bcInvoice.appliesToDocumentNumber = invoice.Original_Invoice_to_Credit__r.InvoiceNo2__c;
		}
		bcInvoice.dueDate = invoice.DueDate__c;
		bcInvoice.vat = invoice.VAT__c * -1;
		bcInvoice.amountInclVAT = invoice.AmountInclVAT_f__c * -1;
		bcInvoice.currencyCode = invoice.CurrencyIsoCode == 'GBP' ? null : invoice.CurrencyIsoCode;
		bcInvoice.lineCount = Integer.valueOf(invoice.LineCount__c);

		List<BusinessCentralCreditNote.SalesLines> bcLines = new List<BusinessCentralCreditNote.SalesLines>();
		for (Invoice_Line__c line : invoice.Invoice_Lines__r) {
			BusinessCentralCreditNote.SalesLines bcLine = new BusinessCentralCreditNote.SalesLines();
			bcLine.number_X = line.NominalCode__c;
			bcLine.salesforceId = line.Id;
			bcLine.productDescription = line.Description__c;
			bcLine.quantity = line.Qty__c * -1;
			bcLine.unitPrice = line.UnitPrice__c;
			bcLine.shipmentDate = line.DeliveryDate__c;
			bcLine.externalDocumentNumber = (line.Order__r.PO_Number__c ?? line.Location_Id__r.PO_Number__c)?.abbreviate(35);
			bcLine.sellToCustomerNumber = line.Location_Id__c;
			bcLine.orderNumber = line.Order__r.OrderNumber;
			bcInvoice.SalesLines.add(bcLine);
		}
		return bcInvoice;
	}

	public void finish(Database.BatchableContext BC) {
		requestChaining.process();
	}
}