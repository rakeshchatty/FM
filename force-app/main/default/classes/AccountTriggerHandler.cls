public class AccountTriggerHandler {

	public void handleTrigger(List<Account> newList, Map<Id, Account> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				setCouncilByPostcode(newList);
			}
			when BEFORE_UPDATE {
				restrictPriceBookChange(newList, oldMap);
				validateFinanceContact(newList, oldMap);
			}
			when AFTER_UPDATE {
				setCouncilByPostcode(newList, oldMap);
				validateSetLiveOrDead(newList, oldMap);
			}
		}
	}

	private static void setCouncilByPostcode(List<Account> newList) {
		for (Account account : newList) {
			if (String.isNotBlank(account.BillingPostalCode)) {
				Doogal.retreiveCouncilByPostCode(account.BillingPostalCode, account.Id);
			}
		}
	}

	private static void setCouncilByPostcode(List<Account> newList, Map<Id, Account> oldMap) {
		for (Account account : newList) {
			if (account.BillingPostalCode != oldMap.get(account.Id).BillingPostalCode && String.isNotBlank(account.BillingPostalCode)) {
				Doogal.retreiveCouncilByPostCode(account.BillingPostalCode, account.Id);
			}
		}
	}

	private static void validateSetLiveOrDead(List<Account> newList, Map<Id, Account> oldMap) {
		Map<Id, Account> eligibleAccounts = new Map<Id, Account>();
		for (Account account : newList) {
			Account oldAccount = oldMap.get(account.Id);
			if ((account.RecordtypeId ==  AccountUtil.RECORDTYPEID_PARENT || account.RecordtypeId == AccountUtil.RECORDTYPEID_PARTNER) &&
				(account.Enqix_Dead_Live__c == 'Dead' || account.Enqix_Dead_Live__c == 'Live') &&
				account.Enqix_Dead_Live__c != oldAccount.Enqix_Dead_Live__c) {
				eligibleAccounts.put(account.Id, account);
			}
		}

		Map<Id, Boolean> doesAccountHaveLiveLocation = LiveLocations.hasLiveLocations(eligibleAccounts.keySet());
		for (Account account : eligibleAccounts.values()) {
			if (account.Enqix_Dead_Live__c == 'Dead' && doesAccountHaveLiveLocation.get(account.Id)) {
				account.Enqix_Dead_Live__c.addError('Cannot be dead as account has live location.');
			}
			if (account.Enqix_Dead_Live__c == 'Live' && !doesAccountHaveLiveLocation.get(account.Id)) {
				account.Enqix_Dead_Live__c.addError('Cannot be live as account does not have live location.');
			}
		}
	}

	private static void restrictPriceBookChange(List<Account> newList, Map<Id, Account> oldMap) {
		for (Account account : newList) {
			if (account.Price_Book__c != oldMap.get(account.Id).Price_Book__c && !(FeatureManagement.checkPermission('AllowPriceBookChange') || CodeOperation.isCodeOperation())) {
				account.addError('You do not have permission to change the PriceBook.');
			}
		}
	}

	private static void validateFinanceContact(List<Account> newList, Map<Id, Account> oldMap) {
		Map<Id, Id> financeContactMap = new Map<Id, Id>();
		for (Account account : newList) {
			if (account.FinanceContact__c != oldMap.get(account.Id).FinanceContact__c && String.isNotBlank(account.FinanceContact__c)) {
				financeContactMap.put(account.Id, account.FinanceContact__c);
			}
		}

		if (financeContactMap.isEmpty()) {
			return;
		}

		List<AccountContactRelation> acrFinanceList = [SELECT AccountId, ContactId FROM AccountContactRelation WHERE Roles INCLUDES('Finance Contact') AND AccountId IN :financeContactMap.keySet() AND ContactId IN :financeContactMap.values()];
		Map<Id, Set<Id>> acrAccountContactsMap = new Map<Id, Set<Id>>();
		for (AccountContactRelation acr : acrFinanceList) {
			if (!acrAccountContactsMap.containsKey(acr.AccountId)) {
				acrAccountContactsMap.put(acr.AccountId, new Set<Id>());
			}
			acrAccountContactsMap.get(acr.AccountId).add(acr.ContactId);
		}

		for (Account account : newList) {
			if (!financeContactMap.containsKey(account.Id)) {
				continue;
			}
            if (!acrAccountContactsMap.containsKey(account.Id) || !acrAccountContactsMap.get(account.Id).contains(account.FinanceContact__c)) {
				account.FinanceContact__c.addError('Invalid contact. Please ensure the contact has a Finance Contact relation to this account.'); // Missing FC role or no ACR on account.
			}
		}
	}
}