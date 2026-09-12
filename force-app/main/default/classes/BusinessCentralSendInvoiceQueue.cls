public without sharing class BusinessCentralSendInvoiceQueue implements Queueable, Database.AllowsCallouts {

	private BusinessCentralCreditNote bcCreditNote;
	private List<BusinessCentralInvoice> bcInvoices;
	private Id recordId;
	private Id requestId;
	private String entityName;
	private Integer currentIndex = 0;

	public BusinessCentralSendInvoiceQueue(BusinessCentralCreditNote bcCreditNote, Id requestId) {
		this.bcCreditNote = bcCreditNote;
		this.recordId = bcCreditNote.salesforceId;
		this.requestId = requestId;
		this.entityName = BusinessCentralRequestChaining.ENTITY_CREDIT_NOTE;
	}

	public BusinessCentralSendInvoiceQueue(List<BusinessCentralInvoice> bcInvoices, Id requestId) {
		this.bcInvoices = bcInvoices;
		this.recordId = bcInvoices[currentIndex].salesforceId;
		this.requestId = requestId;
		this.entityName = BusinessCentralRequestChaining.ENTITY_INVOICE;
	}

	private BusinessCentralSendInvoiceQueue(List<BusinessCentralInvoice> bcInvoices, Id requestId, Integer currentIndex) {
		this(bcInvoices, requestId);
		this.currentIndex = currentIndex;
	}

	public void execute(QueueableContext context) {
		String bcId;
		try {
			if (bcCreditNote != null) {
				bcId = BusinessCentralIntegrationService.sendToBusinessCentral(entityName, JSON.serialize(bcCreditNote).replace('number_X', 'number'), null);
			} else {
				bcId = BusinessCentralIntegrationService.sendToBusinessCentral(entityName, JSON.serialize(bcInvoices[currentIndex]).replace('number_X', 'number'), null);

				if (++currentIndex < bcInvoices.size()) {
					System.enqueueJob(new BusinessCentralSendInvoiceQueue(bcInvoices, requestId, currentIndex));
					return;
				}
			}
		} catch(Exception e) {
			UPDATE new BusinessCentralSendRequest__c(Id = requestId, Status__c = 'Error', ErrorMessage__c = e.getMessage());
			return;
		}

		UPDATE new Invoice_Header__c(Id = recordId, BusinessCentralId__c = bcId, BusinessCentralLastSentDate__c = System.now());
		UPDATE new BusinessCentralSendRequest__c(Id = requestId, InvoiceReference__c = bcId, Status__c = 'Completed', ErrorMessage__c = null);
	}
}