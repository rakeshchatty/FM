public class SendPortalLoginEmailBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

	private Map<Id, AccountContactRelation> allContactsMap = new Map<Id, AccountContactRelation>();

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Date yesterday = System.today() - 1;
		Id locatonRecordTypeId = AccountUtil.RECORDTYPEID_LOCATION;
		String query = 'SELECT AccountId, ContactId, Contact.Email, Contact.Name, Contact.Firstname FROM AccountContactRelation WHERE' +
			' Roles INCLUDES (\'Service Contact\') AND Contact.Email != null AND Account.RecordTypeId = :locatonRecordTypeId AND Account.Enqix_Start_Date__c = :yesterday AND Contact.PortalLoginEmailSent__c = false';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<AccountContactRelation> acrs) {
		Map<Id, AccountContactRelation> contactsMap = new Map<Id, AccountContactRelation>();
		for (AccountContactRelation acr : acrs) {
			if (!allContactsMap.containsKey(acr.ContactId)) {
				allContactsMap.put(acr.ContactId, acr);
				contactsMap.put(acr.ContactId, acr);
			}
		}

		List<SendGridEmail.Input> inputs = new List<SendGridEmail.Input>();
		for (AccountContactRelation acr : contactsMap.values()) {
			SendGridEmail.Input input = new SendGridEmail.Input();
			input.templateId = 'd-bb3b5519832e47c28daf310f092489c2';
			input.toAddress = new List<String>{acr.Contact.Email};
			input.toName = new List<String>{acr.Contact.Name};
			input.greetingName = new List<String>{String.isNotBlank(acr.Contact.Firstname) ? acr.Contact.Firstname : acr.Contact.Name};
			inputs.add(input);
		}

		new SendGridEmail(inputs).send();
	}

	public void finish(Database.BatchableContext batchContext) {
		List<Contact> contacts = new List<Contact>();
		for (AccountContactRelation acr : allContactsMap.values()) {
			contacts.add(new Contact(Id = acr.Contact.Id, AccountId = acr.AccountId, PortalLoginEmailSent__c = true));
		}
		Database.SaveResult[] results = Database.update(contacts, false);
		LogRegister.createLogsUpsert(results, contacts, 'SendPortalLoginEmailBatch update Contact.PortalLoginEmailSent__c = true', 'Update', 'Contact', 'AccountId');
	}
}