public class SendPortalLoginEmailBatch implements Database.Batchable<sObject>, Database.AllowsCallouts, Database.Stateful {

	private Set<Id> allContacts = new Set<Id>();
	private Set<Id> contactsToUpdate = new Set<Id>();

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Id locatonRecordTypeId = AccountUtil.RECORDTYPEID_LOCATION;
		Id parentRecordTypeId = AccountUtil.RECORDTYPEID_PARENT;
		String query = 'SELECT AccountId, ContactId, Contact.Email, Contact.Name, Contact.Firstname, Contact.PortalLoginEmailSentDate__c FROM AccountContactRelation WHERE' +
			' Roles INCLUDES (\'Service Contact\', \'Finance Contact\') AND Contact.Email != null AND Account.RecordTypeId IN (:locatonRecordTypeId, :parentRecordTypeId) AND' +
			' Contact.Last_Portal_Login__c = null AND Account.EffectiveAttribution__c NOT IN (\'Greenzone\', \'Greener Than Green\') AND' +
			' Account.Enqix_Start_Date__c = N_DAYS_AGO:2 AND Contact.PortalLoginEmailSentDate__c = null';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<AccountContactRelation> acrs) {
		Map<Id, AccountContactRelation> contactsMap = new Map<Id, AccountContactRelation>();
		for (AccountContactRelation acr : acrs) {
			if (!allContacts.contains(acr.ContactId)) {
				if (acr.Contact.PortalLoginEmailSentDate__c == null) {
					contactsToUpdate.add(acr.ContactId);
				}
				contactsMap.put(acr.ContactId, acr);
			}
		}

		List<SendGridEmail.Input> inputs = new List<SendGridEmail.Input>();
		for (AccountContactRelation acr : contactsMap.values()) {
			SendGridEmail.Input input = new SendGridEmail.Input();
			if (acr.Contact.PortalLoginEmailSentDate__c == null) {
				input.templateId = 'd-bb3b5519832e47c28daf310f092489c2';
				input.eventType = 'Send Account Setup Reminder Email';
				input.accountId = acr.AccountId;
			}
			input.toAddress = new List<String>{acr.Contact.Email};
			input.toName = new List<String>{acr.Contact.Name};
			input.greetingName = new List<String>{String.isNotBlank(acr.Contact.Firstname) ? acr.Contact.Firstname : acr.Contact.Name};
			inputs.add(input);
		}

		new SendGridEmail(inputs).send();
	}

	public void finish(Database.BatchableContext batchContext) {
		List<Contact> contacts = new List<Contact>();
		for (Id contactId : contactsToUpdate) {
			contacts.add(new Contact(Id = contactId, PortalLoginEmailSentDate__c = System.today()));
		}
		Database.SaveResult[] results = Database.update(contacts, false);
		LogRegister.createLogsUpsert(results, contacts, 'SendPortalLoginEmailBatch update Contact.PortalLoginEmailSentDate__c = today', 'Update', 'Contact', null);
	}
}