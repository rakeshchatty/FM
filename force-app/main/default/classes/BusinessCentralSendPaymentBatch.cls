public without sharing class BusinessCentralSendPaymentBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

	private BusinessCentralRequestChaining requestChaining;
	private Map<String, Id> objectToRequestMap;

	public BusinessCentralSendPaymentBatch(BusinessCentralRequestChaining requestChaining) {
		this.requestChaining = requestChaining;
		this.objectToRequestMap = requestChaining.getRequests(BusinessCentralRequestChaining.ENTITY_PAYMENT);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		Set<String> paymentIds = objectToRequestMap.keySet();
		String query = 'SELECT Id, Entry_Date__c, Unallocated_Amount__c, Document_Name__c, CP_Transactional_Info__c, Credit_Note_Invoice__c, ' +
			'Order__r.OrderNumber, Account__c, CurrencyIsoCode ' +
			'FROM Bank_Statement__c WHERE Id IN :paymentIds';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Bank_Statement__c> scope) {
		List<Bank_Statement__c> bankstatements = new List<Bank_Statement__c>();
		List<BusinessCentralSendRequest__c> bcSendRequests = new List<BusinessCentralSendRequest__c>();

		Set<String> specificInvoices = new Set<String>();
		for (Bank_Statement__c bs : scope) {
			List<String> invoiceIds = extractInvoiceIds(bs.Document_Name__c);
			if (!invoiceIds.isEmpty()) {
				specificInvoices.addAll(invoiceIds);
			}
		}

		Map<Id, String> invoiceIdToNumberMap = new Map<Id, String>();
		if (!specificInvoices.isEmpty()) {
			for (Invoice_Header__c invoice : [SELECT Id, InvoiceNo2__c FROM Invoice_Header__c WHERE Id IN :specificInvoices]) {
				invoiceIdToNumberMap.put(invoice.Id, invoice.InvoiceNo2__c);
			}
		}

		for (Bank_Statement__c bs : scope) {
			BusinessCentralPayment bcPayment = new BusinessCentralPayment();
			bcPayment.postingDate = bs.Entry_Date__c;
			bcPayment.documentNumber = bs.Id;
			bcPayment.salesforceId = bs.Id;
			bcPayment.description = StringUtil.abbreviate(bs.CP_Transactional_Info__c, 100);
			bcPayment.amount = bs.Unallocated_Amount__c;
			bcPayment.balAccountNumber = bs.Account__c;
			bcPayment.orderNumber = bs.Order__r.OrderNumber;
			bcPayment.appliedDocNumbers = extractInvoiceNumbers(extractInvoiceIds(bs.Document_Name__c), invoiceIdToNumberMap);
			bcPayment.currencyCode = bs.CurrencyIsoCode == 'GBP' ? null : bs.CurrencyIsoCode;

			try {
				String bcId = BusinessCentralIntegrationService.sendToBusinessCentral(BusinessCentralRequestChaining.ENTITY_PAYMENT, JSON.serialize(bcPayment), null);
				bankstatements.add(new Bank_Statement__c(Id = bs.Id, BusinessCentralId__c = bcId, BusinessCentralLastSentDate__c = System.now()));
				bcSendRequests.add(new BusinessCentralSendRequest__c(Id = objectToRequestMap.get(bs.Id), PaymentReference__c = bcId, Status__c = 'Completed', ErrorMessage__c = null));
			} catch(Exception e) {
				bcSendRequests.add(new BusinessCentralSendRequest__c(Id = objectToRequestMap.get(bs.Id), Status__c = 'Error', ErrorMessage__c = e.getMessage()));
			}
		}
		UPDATE bankstatements;
		UPDATE bcSendRequests;
	}

	private List<Id> extractInvoiceIds(String documentName) {
		List<Id> invoiceIds = new List<Id>();
		if (String.isNotBlank(documentName) && documentName.contains('Charge for [')) {
			for (String invoiceId : documentName.substring(documentName.indexOf('[')+1, documentName.indexOf(']')).split(',')) {
				invoiceIds.add(invoiceId.trim());
			}
		}
		return invoiceIds;
	}

	private String extractInvoiceNumbers(List<Id> invoiceIds, Map<Id, String> invoiceIdToNumberMap) {
		List<String> invoiceNumbers = new List<String>();
		for (String invoiceId : invoiceIds) {
			invoiceNumbers.add(invoiceIdToNumberMap.get(invoiceId.trim()));
		}
		return String.join(invoiceNumbers, ',');
	}

	public void finish(Database.BatchableContext BC) {}
}