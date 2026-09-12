public with sharing class PaymentChangeEventTriggerHandler extends BusinessCentralEventHandler {

	private static final List<String> ALLOWED_TRANSACTIONS = new List<String>{'Credit Card'};

	public PaymentChangeEventTriggerHandler() {
		super(Bank_Statement__c.sObjectType);
	}

	protected override Map<Id, sObject> fetchRecords(Set<String> recordIds) {
		return new Map<Id, Bank_Statement__c>([SELECT Id, Transaction_type__c, BusinessCentralId__c FROM Bank_Statement__c WHERE Id IN :recordIds]);
	}

	protected override void loadMonitoredFields(Schema.sObjectType sObjectType) {
		// Empty override as there are no monitored fields and no fieldSet
	}	

	protected override Boolean isSkipEvent(EventBus.ChangeEventHeader eventHeader, sObject sObj) {
		return eventHeader.changetype != 'CREATE';
	}

	protected override Boolean isSkipRecord(sObject sObj) {
		return false;
	}

	protected override Boolean isRecordEligible(sObject sObj) {
		Bank_Statement__c bankstatement = (Bank_Statement__c)sObj;
		return ALLOWED_TRANSACTIONS.contains(bankstatement.Transaction_type__c);
	}

	protected override List<BusinessCentralSendRequest__c> createQueueRequests(Set<String> recordIds, List<String> changedFields) {
		List<BusinessCentralSendRequest__c> requests = new List<BusinessCentralSendRequest__c>();
		for (String recordId : recordIds) {
			Bank_Statement__c bankstatement = (Bank_Statement__c)getRecord(recordId);
			requests.add(new BusinessCentralSendRequest__c(PaymentId__c = recordId));
		}
		return requests;
	}

	protected override String getkey(BusinessCentralSendRequest__c requestToQueue) {
		return requestToQueue.PaymentId__c;
	}
}