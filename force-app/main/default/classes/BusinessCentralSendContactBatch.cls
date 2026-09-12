public without sharing class BusinessCentralSendContactBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

	private BusinessCentralRequestChaining requestChaining;
	private Map<String, Id> objectToRequestMap;

	public BusinessCentralSendContactBatch(BusinessCentralRequestChaining requestChaining) {
		this.requestChaining = requestChaining;
		this.objectToRequestMap = requestChaining.getRequests(BusinessCentralRequestChaining.ENTITY_CONTACT);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		Set<String> accountIds = new Set<String>();
		Set<String> contactIds = new Set<String>();

		for (String key : objectToRequestMap.keySet()) {
			List<String> Ids = key.split('-');
			accountIds.add(Ids[0]);
			contactIds.add(Ids[1]);
		}

		String query = 'SELECT Id, FinanceContact__c, FinanceContact__r.FirstName, FinanceContact__r.LastName, ' +
			'FinanceContact__r.Email, BusinessCentralContactId__c ' +
			'FROM Account WHERE Id IN :accountIds AND FinanceContact__c IN :contactIds AND BusinessCentralId__c != null';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> scope) {
		List<Account> accounts = new List<Account>();
		List<BusinessCentralSendRequest__c> bcSendRequests = new List<BusinessCentralSendRequest__c>();
		for (Account account : scope) {
			BusinessCentralContact bcContact = new BusinessCentralContact();
			bcContact.customerNumber = account.Id;
			bcContact.firstName = String.isNotBlank(account.FinanceContact__r.FirstName) ? StringUtil.abbreviate(account.FinanceContact__r.FirstName, 100) : null;
			bcContact.lastName = StringUtil.abbreviate(account.FinanceContact__r.LastName, 30);
			bcContact.email = account.FinanceContact__r.Email;

			String key = account.Id + '-' + account.FinanceContact__c;
			try {
				String bcId = BusinessCentralIntegrationService.sendToBusinessCentral(BusinessCentralRequestChaining.ENTITY_CONTACT, JSON.serialize(bcContact, true), account.BusinessCentralContactId__c);
				accounts.add(new Account(Id = account.Id, BusinessCentralContactId__c = bcId, BusinessCentralContactLastSentDate__c = System.now()));
				bcSendRequests.add(new BusinessCentralSendRequest__c(Id = objectToRequestMap.get(key), ContactReference__c = bcId, Status__c = 'Completed', ErrorMessage__c = null));
			} catch(Exception e) {
				bcSendRequests.add(new BusinessCentralSendRequest__c(Id = objectToRequestMap.get(key), Status__c = 'Error', ErrorMessage__c = e.getMessage()));
			}
		}
		UPDATE accounts;
		UPDATE bcSendRequests;
	}

	public void finish(Database.BatchableContext BC) {
		requestChaining.process();
	}
}