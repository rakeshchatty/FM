public without sharing class SendGridGetMessageQueueable implements Queueable, Database.AllowsCallouts {

	private static final String QUERY = 'last_event_time BETWEEN TIMESTAMP "{0}" AND TIMESTAMP "{1}"';
	private static final String TIME_FORMAT = 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'';
	private DateTime startTime;
	private DateTime endTime;

	public SendGridGetMessageQueueable() {
		this(System.today() - 2, System.today() + 1);
	}

	private SendGridGetMessageQueueable(DateTime startTime, DateTime endTime) {
		this.startTime = startTime;
		this.endTime = endTime;
	}

	public void execute(QueueableContext context) {
		List<EmailActivity> messages = getMessages(String.format(QUERY, new Object[]{startTime.formatGmt(TIME_FORMAT), endTime.formatGmt(TIME_FORMAT)}));
		if (messages.isEmpty() && !Test.isRunningTest()) {
			System.enqueueJob(new SendGridGetSuppressionQueueable());
			return;
		}

		List<Email_Activity__c> activitiesToUpsert = new List<Email_Activity__c>();
		DateTime earliestTime = endTime;
		Set<String> emails = new Set<String>();
		for (EmailActivity message : messages) {
			Email_Activity__c activity = message.convert();
			activitiesToUpsert.add(activity);
			if (activity.Event_Time__c < earliestTime) {
				earliestTime = activity.Event_Time__c;
			}

			emails.add(activity.To_Email__c);
			emails.add(activity.From_Email__c);
		}

        List<Contact> contacts = [SELECT Email, LastEmailReceived__c FROM Contact WHERE Email IN :emails];
		Map<String, Contact> emailToContact = new Map<String, Contact>();
        for (Contact contact : contacts) {
            emailToContact.put(contact.Email, contact);
        }

        Map<Id, Contact> contactsToUpdate = new Map<Id, Contact>();
		Contact contact;
		for (Email_Activity__c activity : activitiesToUpsert) {
            if (emailToContact.containsKey(activity.To_Email__c)) {
                contact = emailToContact.get(activity.To_Email__c);
				activity.Email_Sent_To__c = contact.Id;

				if (contact.LastEmailReceived__c == null || contact.LastEmailReceived__c < activity.Event_Time__c) {
					contact.LastEmailReceived__c = activity.Event_Time__c;
					contactsToUpdate.put(contact.Id, contact);
				}
            }
            if (emailToContact.containsKey(activity.From_Email__c)) {
                activity.Email_From__c = emailToContact.get(activity.From_Email__c).Id;
            }
        }

		if (!activitiesToUpsert.isEmpty()) {
			Database.UpsertResult[] results = Database.upsert(activitiesToUpsert, Email_Activity__c.Message_Id__c, false);
			LogRegister.createLogsUpsert(results, activitiesToUpsert, 'Upsert Email Activities', 'Upsert', 'Email_Activity__c', null);
		}
		if (!contactsToUpdate.isEmpty()) {
			Database.SaveResult[] results = Database.update(contactsToUpdate.values(), false);
			LogRegister.createLogsUpsert(results, contactsToUpdate.values(), 'Update Contact Last Email Received', 'Update', 'Contact', null);
		}

		if (messages.size() == 1000) {
			System.enqueueJob(new SendGridGetMessageQueueable(startTime, earliestTime));
		} else if (!Test.isRunningTest()) {
		   	System.enqueueJob(new SendGridGetSuppressionQueueable());
		}
	}

	private List<EmailActivity> getMessages(String query) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:SendGrid/messages?limit=1000&query=' + EncodingUtil.urlEncode(query, 'UTF-8').replaceAll('\\+','%20'));
		request.setMethod('GET');

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			return new List<EmailActivity>();
		}
		Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
		String messages = JSON.serialize(jsonMap.get('messages'));
		return (List<EmailActivity>)JSON.deserialize(messages, List<EmailActivity>.class);
	}

	private class EmailActivity {
		private String msg_id;
		private String subject;
		private String from_email;
		private String to_email;
		private String status;
		private Integer opens_count;
		private Integer clicks_count;
		private DateTime last_event_time;

		private Email_Activity__c convert() {
			return new Email_Activity__c(Message_Id__c = msg_id, Subject__c = subject, From_Email__c = from_email, To_Email__c = to_email,
				Status__c = status, Count_of_Opens__c = opens_count, Count_of_Clicks__c = clicks_count, Event_Time__c = last_event_time);
		}
	}
}