public without sharing class AccountChangeEventTriggerHandler extends BusinessCentralEventHandler {

	private static final Set<Id> ALLOWED_RECORD_TYPES = new Set<Id>();
	private static final String FIELD_FINANCE_CONTACT = 'FinanceContact__c';
	private static final String FIELD_LAST_MODIFIED = 'LastModifiedDate';

	private static final Set<String> COMPOSITE_FIELDS = new Set<String> {'BillingAddress.Street', 'BillingAddress.City', 'BillingAddress.County', 'BillingAddress.PostalCode', 'BillingAddress.Country'};

	public AccountChangeEventTriggerHandler() {
		super(Account.sObjectType);

		ALLOWED_RECORD_TYPES.add(AccountUtil.RECORDTYPEID_LOCATION);
		ALLOWED_RECORD_TYPES.add(AccountUtil.RECORDTYPEID_PARENT);
		ALLOWED_RECORD_TYPES.add(AccountUtil.RECORDTYPEID_PARTNER);
	}

	protected override void loadMonitoredFields(Schema.sObjectType sObjectType) {
		super.loadMonitoredFields(sObjectType);
		monitoredFields.addAll(COMPOSITE_FIELDS);
	}

	protected override Map<Id, sObject> fetchRecords(Set<String> recordIds) {
		return new Map<Id, Account>([SELECT BusinessCentralId__c, BusinessCentralContactId__c, RecordTypeId, Parter_type__c, FinanceContact__c, Enqix_Dead_Live__c FROM Account WHERE Id IN :recordIds]);
	}

	protected override Boolean isSkipEvent(EventBus.ChangeEventHeader eventHeader, sObject sObj) {
		return eventHeader.changetype != 'UPDATE' || !isChangedFieldsInMonitoredFields(eventHeader);
	}

	protected override Boolean isSkipRecord(sObject sObj) {
		Account account = (Account)sObj;
		return !AccountUtil.isLive(account) && String.isEmpty(account.BusinessCentralId__c);
	}

	protected override Boolean isRecordEligible(sObject sObj) {
		Account account = (Account)sObj;
		return ALLOWED_RECORD_TYPES.contains(account.RecordTypeId) &&
			(account.RecordTypeId == AccountUtil.RECORDTYPEID_LOCATION || account.FinanceContact__c != null);
	}

	protected override List<BusinessCentralSendRequest__c> createQueueRequests(Set<String> recordIds, List<String> changedFields) {
		Boolean isFinanceContactChanged = changedFields.contains(FIELD_FINANCE_CONTACT);
		Boolean isOnlyFinanceContactChanged = isFinanceContactChanged && (changedFields.size() == 1 || (changedFields.size() == 2 && changedFields.contains(FIELD_LAST_MODIFIED)));

		List<BusinessCentralSendRequest__c> requests = new List<BusinessCentralSendRequest__c>();
		for (String recordId : recordIds) {
			Account account = (Account)getRecord(recordId);

			if (String.isBlank(account.BusinessCentralContactId__c) && account.RecordTypeId != AccountUtil.RECORDTYPEID_LOCATION) {
				requests.add(new BusinessCentralSendRequest__c(AccountId__c = recordId, ContactId__c = account.FinanceContact__c));
			}
			if (!isOnlyFinanceContactChanged) {
				requests.add(new BusinessCentralSendRequest__c(AccountId__c = recordId));
			}
		}
		return requests;
	}

	protected override String getkey(BusinessCentralSendRequest__c requestToQueue) {
		return String.isNotBlank(requestToQueue.ContactId__c) ? requestToQueue.AccountId__c + '-' + requestToQueue.ContactId__c : requestToQueue.AccountId__c;
	}
}