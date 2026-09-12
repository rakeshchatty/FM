public without sharing class SendGridGetSuppressionQueueable implements Queueable, Database.AllowsCallouts {

	private static final String PARAMS ='{0}?start_time={1}&end_time={2}&limit=500&offset={3}';
	private String suppressionType;
	private DateTime startTime;
	private DateTime endTime;
	private Integer offset;

	public SendGridGetSuppressionQueueable() {
		this('bounces');
	}

	@TestVisible
	private SendGridGetSuppressionQueueable(String suppressionType) {
		this(suppressionType, 0);
	}

	private SendGridGetSuppressionQueueable(String suppressionType, Integer offset) {
		this.suppressionType = suppressionType;
		this.offset = offset;
		DateTime today = System.today();
		this.startTime = today - 2;
		this.endTime = today + 1;
	}

	public void execute(QueueableContext context) {
		List<Suppression> suppressions = getSuppressions(String.format(PARAMS, new Object[]{suppressionType, startTime.getTime() / 1000, endTime.getTime() / 1000, offset}));

		Map<String, String> emailToReason = new Map<String, String>();
		for (Suppression suppression : suppressions) {
			emailToReason.put(suppression.email, suppression.reason);
		}

		if (!emailToReason.isEmpty()) {
			List<Email_Activity__c> activitiesToUpdate = new List<Email_Activity__c>();
			for (Email_Activity__c activity : [SELECT Id, To_Email__c FROM Email_Activity__c WHERE CreatedDate = TODAY AND To_Email__c IN :emailToReason.keySet()]) {
				activity.Event__c = suppressionType; // Blocked or Bounced
				activity.Reason__c = emailToReason.get(activity.To_Email__c);
				activitiesToUpdate.add(activity);
			}

			if (!activitiesToUpdate.isEmpty()) {
				Database.SaveResult[] results = Database.update(activitiesToUpdate, false);
				LogRegister.createLogsUpsert(results, activitiesToUpdate, 'Update Email Activity Suppression', 'Update', 'Email_Activity__c', null);
			}
		}

		if (suppressions.size() == 500) {
			System.enqueueJob(new SendGridGetSuppressionQueueable(suppressionType, offset + 500));
		} else if (suppressionType == 'bounces' && !Test.isRunningTest()) {
		   	System.enqueueJob(new SendGridGetSuppressionQueueable('blocks'));
		}
	}

	private List<Suppression> getSuppressions(String params) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:SendGrid/suppression/' + params);
		request.setMethod('GET');

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			return new List<Suppression>();
		}

		return (List<Suppression>)JSON.deserialize(response.getBody(), List<Suppression>.class);
	}

	private class Suppression {
		private String email;
		private String reason;
	}
}