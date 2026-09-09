public without sharing class ContactDeletion {

		public ContactDeletion(List<Contact> contacts) {
			validateFinanceContact(contacts);
		}

		private void validateFinanceContact(List<Contact> contacts) {
			Map<Id, List<Account>> financeContactWithAccountMap = new Map<Id, List<Account>>();
			for (Account account : [SELECT Name, FinanceContact__c FROM Account 
				WHERE FinanceContact__c IN :contacts AND Enqix_Dead_Live__c = :AccountUtil.LIVE 
				AND RecordTypeId IN (:AccountUtil.RECORDTYPEID_PARENT, :AccountUtil.RECORDTYPEID_PARTNER)]) {
				if (!financeContactWithAccountMap.containsKey(account.FinanceContact__c)) {
					financeContactWithAccountMap.put(account.FinanceContact__c, new List<Account>());
				}
				financeContactWithAccountMap.get(account.FinanceContact__c).add(account);
			}

			for (Contact contact : contacts) {
				if (!financeContactWithAccountMap.containsKey(contact.Id)) {
					continue;
				}
				contact.addError('Finance contact is required on live account: ' + prepareErrorMessage(financeContactWithAccountMap.get(contact.Id)));
			}
		}

		private String prepareErrorMessage(List<Account> accounts) {
			List<String> errorMessage = new List<String>();
			for (Account account : accounts) {
				errorMessage.add(account.Name + ' [' + account.Id + ']');
			}
			return String.join(errorMessage, ', ');
		}
	}