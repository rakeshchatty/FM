public class InvoiceChangeEventTriggerHandler extends BusinessCentralEventHandler {

	private static final Date CUT_OFF_DATE = Date.newInstance(2026, 5, 28);

	public InvoiceChangeEventTriggerHandler() {
		super(Invoice_Header__c.sObjectType);
	}

	protected override Map<Id, sObject> fetchRecords(Set<String> recordIds) {
		return new Map<Id, Invoice_Header__c>([SELECT BusinessCentralId__c, Status__c, LineCount__c, DueDate__c, AmountExclVAT__c FROM Invoice_Header__c WHERE Id IN :recordIds]);
	}

	protected override Boolean isSkipEvent(EventBus.ChangeEventHeader eventHeader, sObject sObj) {
		Invoice_Header__c invoice = (Invoice_Header__c)sObj;

		if (eventHeader.changetype == 'CREATE') {
			return invoice.Status__c != Invoicing.STATUS_CLOSED;
		} else if (eventHeader.changetype == 'UPDATE') {
			return !isChangedFieldsInMonitoredFields(eventHeader) || invoice.Status__c != Invoicing.STATUS_CLOSED;
		} else {
			return true;
		}
	}

	protected override Boolean isSkipRecord(sObject sObj) {
        Invoice_Header__c invoice = (Invoice_Header__c)sObj;
		return invoice.AmountExclVAT__c == 0;
	}

	protected override Boolean isRecordEligible(sObject sObj) {
		Invoice_Header__c invoice = (Invoice_Header__c)sObj;
		return String.isEmpty(invoice.BusinessCentralId__c) && invoice.LineCount__c > 0 && invoice.DueDate__c >= CUT_OFF_DATE;
	}

	protected override List<BusinessCentralSendRequest__c> createQueueRequests(Set<String> recordIds, List<String> changedFields) {
		List<BusinessCentralSendRequest__c> requests = new List<BusinessCentralSendRequest__c>();
		for (String recordId : recordIds) {
			requests.add(new BusinessCentralSendRequest__c(InvoiceId__c = recordId));
		}
		return requests;
	}

	protected override String getkey(BusinessCentralSendRequest__c requestToQueue) {
		return requestToQueue.InvoiceId__c;
	}
}