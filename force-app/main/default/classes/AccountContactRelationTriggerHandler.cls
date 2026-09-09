public without sharing class AccountContactRelationTriggerHandler {

	public void handleTrigger(List<AccountContactRelation> newList, Map<Id, AccountContactRelation> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT, AFTER_UPDATE {
				setFinanceContactOnAccount(newList);
			}
			when BEFORE_DELETE {
				validateFinanceContact(oldMap);
			}
		}
	}

	private void validateFinanceContact(Map<Id, AccountContactRelation> oldMap) {
		List<AccountContactRelation> acrs = [SELECT Id, Roles, ContactId, Account.Name, Account.RecordTypeId, Account.FinanceContact__c FROM AccountContactRelation WHERE Id IN :oldMap.keySet()];
		for (AccountContactRelation acr : acrs) {
			if (!acr.Roles.contains(AcrUtil.FINANCE_ROLE) || (acr.Account.RecordTypeId != AccountUtil.RECORDTYPEID_PARENT && acr.Account.RecordTypeId != AccountUtil.RECORDTYPEID_PARTNER)) {
				continue;
			}

			if (acr.ContactId == acr.Account.FinanceContact__c) {
				oldMap.get(acr.Id).addError('Finance contact is required on this account: ' + acr.Account.Name + ' [' + acr.AccountId + ']');
			}
		}
	}

	private void setFinanceContactOnAccount(List<AccountContactRelation> newList) {
        List<AccountContactRelation> acrs = [SELECT AccountId, Account.FinanceContact__c, ContactId, Contact.Email 
                                             FROM AccountContactRelation 
                                             WHERE Id IN :newList AND Account.FinanceContact__c = null AND 
                                             Account.RecordTypeId IN (:AccountUtil.RECORDTYPEID_PARENT, :AccountUtil.RECORDTYPEID_PARTNER) AND 
                                             Roles INCLUDES (:AcrUtil.FINANCE_ROLE) AND Contact.Email != null];
		Map<Id, Account> accountMap = new Map<Id, Account>();
		for (AccountContactRelation acr : acrs) {
            accountMap.put(acr.AccountId, new Account(Id = acr.AccountId, FinanceContact__c = acr.ContactId));
		}
        UPDATE accountMap.values();
	}
}