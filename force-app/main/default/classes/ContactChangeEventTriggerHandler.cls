public without sharing class ContactChangeEventTriggerHandler extends BusinessCentralEventHandler {

	private static final Set<String> COMPOSITE_FIELDS = new Set<String> {'Name.FirstName', 'Name.LastName'};

	public ContactChangeEventTriggerHandler() {
		super(Contact.sObjectType);
	}

	protected override Map<Id, sObject> fetchRecords(Set<String> recordIds) {
		return new Map<Id, Contact>([SELECT Id, (SELECT Id, BusinessCentralId__c, BusinessCentralContactId__c FROM Accounts__r WHERE BusinessCentralId__c != null) FROM Contact WHERE Id IN :recordIds]);
	}

	protected override void loadMonitoredFields(Schema.sObjectType sObjectType) {
		super.loadMonitoredFields(sObjectType);
		monitoredFields.addAll(COMPOSITE_FIELDS);
	}

	protected override Boolean isSkipEvent(EventBus.ChangeEventHeader eventHeader, sObject sObj) {
		return eventHeader.changetype != 'UPDATE' || !isChangedFieldsInMonitoredFields(eventHeader);
	}

	protected override Boolean isSkipRecord(sObject sObj) {
		return false;
	}

	protected override Boolean isRecordEligible(sObject sObj) {
		Contact contact = (Contact)sObj;
		return !contact.Accounts__r.isEmpty();
	}

	protected override List<BusinessCentralSendRequest__c> createQueueRequests(Set<String> recordIds, List<String> changedFields) {
		List<BusinessCentralSendRequest__c> requests = new List<BusinessCentralSendRequest__c>();
		for (String recordId : recordIds) {
			Contact contact = (Contact)getRecord(recordId);
			for (Account account : contact.Accounts__r) {
				requests.add(new BusinessCentralSendRequest__c(AccountId__c = account.Id, ContactId__c = recordId));
			}
		}
		return requests;
	}

	protected override String getkey(BusinessCentralSendRequest__c requestToQueue) {
		return requestToQueue.AccountId__c;
	}
}