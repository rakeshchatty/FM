public with sharing class BusinessCentralSendAccountBatch implements Database.Batchable<sObject>, Database.Stateful, Database.AllowsCallouts {

	private BusinessCentralRequestChaining requestChaining;
	private Map<String, Id> objectToRequestMap;

	public BusinessCentralSendAccountBatch(BusinessCentralRequestChaining requestChaining) {
		this.requestChaining = requestChaining;
		this.objectToRequestMap = requestChaining.getRequests(BusinessCentralRequestChaining.ENTITY_ACCOUNT);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		Set<String> accountIds = objectToRequestMap.keySet();
		String query = 'SELECT Id, Name, RecordType.Name, CP_Account_Code__c, Enqix_Dead_Live__c, Account_Service_Status__c, ' +
			'ParentId, Partnership__c, Partnership__r.Parter_type__c, Account_Manager__r.Name, CreditControlManager__r.Name, ' +
			'BillingStreetLine1__c, BillingStreetLine2__c, BillingCity, BillingCountryCode, BillingPostalCode, CreditDays__c, Branch__c, ' +
			'Enqix_Payment_Method__c, dd_sort_code__c, dd_account_number__c, dd_account_holder__c, BusinessCentralId__c, EffectiveCurrencyCode__c ' +
			'FROM Account WHERE Id IN :accountIds ORDER BY ParentId NULLS FIRST'; // Order of Parent(Account)/Partner/Location is controlled by ParentId NULLS FIRST
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> scope) {
		List<Account> accounts = new List<Account>();
		List<BusinessCentralSendRequest__c> bcSendRequests = new List<BusinessCentralSendRequest__c>();
		for (Account account : scope) {
			BusinessCentralAccount bcAccount = new BusinessCentralAccount();
			bcAccount.number_X = account.Id;
			bcAccount.Name = StringUtil.abbreviate(account.Name, 100);
			bcAccount.type = getType(account.RecordType.Name);
			bcAccount.code = account.CP_Account_Code__c;
			bcAccount.isLive = account.Enqix_Dead_Live__c == AccountUtil.LIVE;
			bcAccount.bidNumber = account.Partnership__r.Parter_type__c == AccountUtil.PARTNER_TYPE_BID ? account.Partnership__c : null;
			bcAccount.managerName = account.Account_Manager__r.Name;
			bcAccount.creditControllerName = account.CreditControlManager__r.Name;
			bcAccount.addressLine1 = account.BillingStreetLine1__c;
			bcAccount.addressLine2 = account.BillingStreetLine2__c;
			bcAccount.city = StringUtil.abbreviate(account.BillingCity, 30);
			bcAccount.country = account.BillingCountryCode;
			bcAccount.postalCode = account.BillingPostalCode;
			bcAccount.paymentTermsCode = account.CreditDays__c;
			bcAccount.branch = account.Branch__c;
			bcAccount.currencyCode = account.EffectiveCurrencyCode__c == 'GBP' ? null : account.EffectiveCurrencyCode__c;
			if (bcAccount.type == 'Location') {
				bcAccount.billToCustomerNumber = account.ParentId;
			} else { // Parent or Partner
				bcAccount.paymentMethodCode = PaymentUtil.transformPaymentMethodCode(account.Enqix_Payment_Method__c);
				bcAccount.serviceStatus = account.Account_Service_Status__c;
				bcAccount.accountTitle = StringUtil.abbreviate(account.dd_account_holder__c, 100);
				bcAccount.bankAccountNumber = StringUtil.abbreviate(account.dd_account_number__c, 30);
				bcAccount.bankSortCode = StringUtil.abbreviate(account.dd_sort_code__c, 20);
			}

			String bcId;
			try {
				bcId = BusinessCentralIntegrationService.sendToBusinessCentral(BusinessCentralRequestChaining.ENTITY_ACCOUNT, JSON.serialize(bcAccount).replace('number_X', 'number'), account.BusinessCentralId__c);
				accounts.add(new Account(Id = account.Id, BusinessCentralId__c = bcId, BusinessCentralLastSentDate__c = System.now()));
				bcSendRequests.add(new BusinessCentralSendRequest__c(Id = objectToRequestMap.get(account.Id), AccountReference__c = bcId, Status__c = 'Completed', ErrorMessage__c = null));
			} catch(Exception e) {
				bcSendRequests.add(new BusinessCentralSendRequest__c(Id = objectToRequestMap.get(account.Id), Status__c = 'Error', ErrorMessage__c = e.getMessage()));
			}
		}
		UPDATE accounts;
		UPDATE bcSendRequests;
	}

	private String getType(String recordTypeName) {
		switch on recordTypeName.toUpperCase() {
			WHEN 'LOCATION' {
				return 'Location';
			}
			WHEN 'ACCOUNT' {
				return 'Parent';
			}
			WHEN 'PARTNER' {
				return 'Partner';
			}
		}
		return null;
	}

	public void finish(Database.BatchableContext BC) {
		requestChaining.process();
	}
}