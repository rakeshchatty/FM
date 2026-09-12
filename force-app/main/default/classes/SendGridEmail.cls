public without sharing class SendGridEmail {

	private static final Integer STATUS_SUCCESS = 202;
	private static final SendGridSetting__c SEND_GRID = SendGridSetting__c.getOrgDefaults();
	private static final List<String> DISABLED_TEMPLATE_IDS = new List<String>{'d-bb3b5519832e47c28daf310f092489c2', 'd-c8ab2f042caf418a8dac48152e4acb94', 'd-a123be97e75e4bea8b157b0ff87a1648'};
	private Input[] inputs;

	public class Input {
		@InvocableVariable(required=true label='Template Id')
		public String templateId;
		@InvocableVariable(required=false label='From Name')
		public String fromName;
		@InvocableVariable(required=false label='From Email')
		public String fromEmail;

		@InvocableVariable(required=true label='To Address')
		public List<String> toAddress;
		@InvocableVariable(required=true label='To Name')
		public List<String> toName;
		@InvocableVariable(required=false label='Greeting Name')
		public List<String> greetingName;

		@InvocableVariable(required=false label='Subject')
		public String subject;

		@InvocableVariable(required=false label='Collection of Records')
		public List<sObject> collection = new List<sObject>();

		@InvocableVariable(required=false)
		public String var01, var02, var03, var04, var05, var06, var07, var08, var09, var10,
					  var11, var12, var13, var14, var15, var16, var17, var18, var19, var20;

		@InvocableVariable(required=false)
		public Id contentDocumentId;
		@InvocableVariable(required=false)
		public List<Id> contentDocumentIds;
		@InvocableVariable(required=false)
		public Boolean isAttachmentInline = false;

		@InvocableVariable(required=false label='Event Type')
		public String eventType;
		@InvocableVariable(required=false label='Account Id')
		public String accountId;
		@InvocableVariable(required=false label='Attribution')
		public String attribution;
	}

	public SendGridEmail() {}

	public SendGridEmail(Input[] inputs) {
		this.inputs = inputs;
	}

	@InvocableMethod(label='Send Email via SendGrid')
	public static void send(Input[] inputs) {
		if (!SEND_GRID.IsFlowEmailEnabled__c) {
			return;
		}

		new SendGridEmail(inputs).send();
	}

	public void send() {
		List<SendGridRequestLog__c> requestLogs = new List<SendGridRequestLog__c>();
		for (Input input : inputs) {
			createHubSpotEvent(input);
			if (!DISABLED_TEMPLATE_IDS.contains(input.templateId)) {
				Boolean hasAttachments = (input.contentDocumentId != null) || (input.contentDocumentIds != null && !input.contentDocumentIds.isEmpty());
				removeDuplicateRecipient(input);	// Avoid duplicate emails, as SendGrid will fail
				requestLogs.add(new SendGridRequestLog__c(TemplateId__c = input.templateId, HasAttachment__c = hasAttachments, Request__c = JSON.serialize(input)));
			}
		}

		if (!requestLogs.isEmpty()) {
			INSERT requestLogs;
		}
	}

	public void send(SendGridEvent__e event) {
		if (!SEND_GRID.IsEmailEnabled__c) {
			return;
		}

		Input input = (Input)JSON.deserialize(event.JsonBody__c, Input.class);
		Body body = new Body();
		body.template_id = input.templateId;
		body.from_email = new Email(String.isNotBlank(input.fromEmail) ? input.fromEmail : SEND_GRID.FromEmail__c,
									String.isNotBlank(input.fromName) ? input.fromName : SEND_GRID.FromName__c);
		body.reply_to = body.from_email;
		body.personalizations = setupPersonalizations(input);
		body.attachments = setupAttachments(input);

		SendGridEmail.post(event.RequestLogId__c, JSON.serialize(body, true).replace('from_email', 'from'));
	}

	private void removeDuplicateRecipient(Input input) {
		List<String> toAddressUnique = new List<String>();
		List<String> toNameUnique = new List<String>();

		for (Integer i=0; i<input.toAddress.size(); i++) {
			if (toAddressUnique.contains(input.toAddress[i])) {
				continue;
			}
			toAddressUnique.add(input.toAddress[i]);
			toNameUnique.add(input.toName[i]);
		}

		input.toAddress = toAddressUnique;
		input.toName = toNameUnique;
	}

	private List<Attachment> setupAttachments(Input input) {
		if (input.contentDocumentId == null && (input.contentDocumentIds == null || input.contentDocumentIds.isEmpty())) {
			return null;
		}

		List<Id> contentDocumentIds = new List<Id>();
		if (input.contentDocumentIds != null && !input.contentDocumentIds.isEmpty()) {
			contentDocumentIds.addAll(input.contentDocumentIds);
		} else {
			contentDocumentIds.add(input.contentDocumentId);
		}

		List<Id> contentVersionIds = new List<Id>();
		for (ContentDocument contentDocument : [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id IN :contentDocumentIds]) {
			contentVersionIds.add(contentDocument.LatestPublishedVersionId);
		}

		List<Attachment> attachments = new List<Attachment>();
		for (ContentVersion contentVersion : [SELECT Title, FileExtension, VersionData FROM ContentVersion WHERE Id IN :contentVersionIds]) {
			Attachment attachment = new Attachment();
			attachment.filename = contentVersion.Title.containsIgnoreCase(contentVersion.FileExtension) ? contentVersion.Title : contentVersion.Title + '.' + contentVersion.FileExtension;
			attachment.content = EncodingUtil.base64Encode(contentVersion.VersionData);
			if (input.isAttachmentInline) {
				attachment.disposition = 'inline';
				attachment.content_id = 'inlineContent';
			}
			attachments.add(attachment);
		}

		return attachments;
	}

	private List<Personalization> setupPersonalizations(Input input) {
		List<Personalization> personalizations = new List<Personalization>();

		Map<String, Object> dynamicTemplateData = setupTemplateMergeFields(input);

		for (Integer i=0; i<input.toAddress.size(); i++) {
			Personalization personalization = new Personalization();
			personalization.to = new List<Email>{new Email(input.toAddress[i], input.toName[i])};
			personalization.dynamic_template_data = new Map<String, Object>(dynamicTemplateData);
			personalization.dynamic_template_data.put('fullName', input.toName[i]);
			personalization.dynamic_template_data.put('subject', input.subject);
			personalization.dynamic_template_data.put('attribution', input.attribution);
			personalizations.add(personalization);
		}
		if (input.greetingName != null) {
			for (Integer i=0; i<input.toAddress.size(); i++) {
				personalizations[i].dynamic_template_data.put('greetingName', input.greetingName[i]);
			}
		}

		return personalizations;
	}

	private Map<String, Object> setupTemplateMergeFields(Input input) {
		Map<String, Object> dynamicTemplateData = new Map<String, Object>();

		if (String.isNotBlank(input.var01)) {
			dynamicTemplateData.put('var01', input.var01);
		}
		if (String.isNotBlank(input.var02)) {
			dynamicTemplateData.put('var02', input.var02);
		}
		if (String.isNotBlank(input.var03)) {
			dynamicTemplateData.put('var03', input.var03);
		}
		if (String.isNotBlank(input.var04)) {
			dynamicTemplateData.put('var04', input.var04);
		}
		if (String.isNotBlank(input.var05)) {
			dynamicTemplateData.put('var05', input.var05);
		}
		if (String.isNotBlank(input.var06)) {
			dynamicTemplateData.put('var06', input.var06);
		}
		if (String.isNotBlank(input.var07)) {
			dynamicTemplateData.put('var07', input.var07);
		}
		if (String.isNotBlank(input.var08)) {
			dynamicTemplateData.put('var08', input.var08);
		}
		if (String.isNotBlank(input.var09)) {
			dynamicTemplateData.put('var09', input.var09);
		}
		if (String.isNotBlank(input.var10)) {
			dynamicTemplateData.put('var10', input.var10);
		}
		if (String.isNotBlank(input.var11)) {
			dynamicTemplateData.put('var11', input.var11);
		}
		if (String.isNotBlank(input.var12)) {
			dynamicTemplateData.put('var12', input.var12);
		}
		if (String.isNotBlank(input.var13)) {
			dynamicTemplateData.put('var13', input.var13);
		}
		if (String.isNotBlank(input.var14)) {
			dynamicTemplateData.put('var14', input.var14);
		}
		if (String.isNotBlank(input.var15)) {
			dynamicTemplateData.put('var15', input.var15);
		}
		if (String.isNotBlank(input.var16)) {
			dynamicTemplateData.put('var16', input.var16);
		}
		if (String.isNotBlank(input.var17)) {
			dynamicTemplateData.put('var17', input.var17);
		}
		if (String.isNotBlank(input.var18)) {
			dynamicTemplateData.put('var18', input.var18);
		}
		if (String.isNotBlank(input.var19)) {
			dynamicTemplateData.put('var19', input.var19);
		}
		if (String.isNotBlank(input.var20)) {
			dynamicTemplateData.put('var20', input.var20);
		}

		if (input.collection != null) {
			dynamicTemplateData.put('collection', input.collection);
		}

		return dynamicTemplateData;
	}

	@future (callout=true)
	private static void post(Id requestLogId, String body) {
		System.OrgLimit apiRequestsLimit = OrgLimits.getMap().get('DailyApiRequests');
		SendGridRequestLog__c requestLog = new SendGridRequestLog__c(Id = requestLogId, isResponseUpdated__c = true, Status__c = 'Sent',
			DailyApiLimit__c = apiRequestsLimit.getLimit(), DailyApiUsage__c = apiRequestsLimit.getValue());
		try {
			HttpResponse response = post(body);
			requestLog.ResponseStatusCode__c = response.getStatusCode();
			if (requestLog.ResponseStatusCode__c != STATUS_SUCCESS) {
				requestLog.Status__c = 'Error';
				requestLog.Response__c = response.getBody();
			}
		} catch (Exception e) {
			requestLog.Status__c = 'Error';
			requestLog.Response__c = e.getMessage();
		}

		UPDATE requestLog;
	}

	private static HttpResponse post(String body) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:SendGrid/mail/send');
		request.setMethod('POST');
		request.setBody(body);
		return new Http().send(request);
	}

	private class Body {
		private String template_id;
		private Email from_email; // This cannot be "from" as it is a keyword
		private Email reply_to;
		private List<Attachment> attachments;
		private List<Personalization> personalizations;
		private String attribution;
	}

	private class Attachment {
		private String content;
		private String filename;
		private String type;
		private String disposition;
		private String content_id;
	}

	private class Personalization {
		private List<Email> to;
		private Map<String, Object> dynamic_template_data;
	}

	private class Email {
		private String email;
		private String name;

		private Email(String email, String name) {
			this.email = email;
			this.name = name;
		}
	}

	private static void createHubSpotEvent(Input input) {
		if (input.eventType == null || input.accountId == null) {
			return;
		}

		HubSpotEvent__c hubspotEvent = new HubSpotEvent__c();
		hubspotEvent.EventType__c = input.eventType;
		hubspotEvent.AccountId__c = input.accountId;
		hubspotEvent.GreetingName__c = (input.greetingName == null || input.greetingName.isEmpty()) ? '' : String.join(input.greetingName, ', ');
		hubspotEvent.ToAddress__c = String.join(input.toAddress, ', ');
		hubspotEvent.ToName__c = String.join(input.toName, ', ');
		hubspotEvent.Value01__c = input.var01;
		hubspotEvent.Value02__c = input.var02;
		hubspotEvent.Value03__c = input.var03;
		hubspotEvent.Value04__c = input.var04;
		hubspotEvent.Value05__c = input.var05;

		Database.SaveResult result = Database.insert(hubSpotEvent, false);
		LogRegister.createLogsUpsert(new List<Database.SaveResult>{result}, new List<HubSpotEvent__c>{hubspotEvent}, 'Create HubSpotEvent', 'Insert', 'HubSpotEvent__c', null);

		if (!input.collection.isEmpty()) {
			List<HubSpotEventLine__c> hubSpotEventLines = new List<HubSpotEventLine__c>();
			sObject sObj = input.collection[0];
			if (String.valueOf(sObj.Id.getSObjectType()) == 'CollectionAggregator__c') {
				for (sObject record : input.collection) {
					hubSpotEventLines.add(createAggregatorLine((CollectionAggregator__c)record, hubSpotEvent.Id));
				}
			}

			Database.SaveResult[] results = Database.insert(hubSpotEventLines, false);
			LogRegister.createLogsUpsert(results, hubSpotEventLines, 'Create HubSpotEventLines', 'Insert', 'HubSpotEventLine__c', 'Event__c');
		}
	}

	private static HubSpotEventLine__c createAggregatorLine(CollectionAggregator__c collectionAggregator, Id hubSpotEventId) {
		HubSpotEventLine__c hubSpotEventLine = new HubSpotEventLine__c();
		hubSpotEventLine.ObjectType__c = 'Collection Aggregator';
		hubSpotEventLine.Event__c = hubSpotEventId;
		hubSpotEventLine.Value01__c = collectionAggregator.SupplierProductName__c;
		hubSpotEventLine.Value02__c = collectionAggregator.Monday__c;
		hubSpotEventLine.Value03__c = collectionAggregator.Tuesday__c;
		hubSpotEventLine.Value04__c = collectionAggregator.Wednesday__c;
		hubSpotEventLine.Value05__c = collectionAggregator.Thursday__c;
		hubSpotEventLine.Value06__c = collectionAggregator.Friday__c;
		hubSpotEventLine.Value07__c = collectionAggregator.Saturday__c;
		hubSpotEventLine.Value08__c = collectionAggregator.Sunday__c;

		return hubSpotEventLine;
	}
}