public without sharing class SendGridEmail {

	private static final Integer STATUS_SUCCESS = 202;
	private static final SendGridSetting__c SEND_GRID = SendGridSetting__c.getOrgDefaults();
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

		@InvocableVariable(required=false label='Collection of Records')
		public List<sObject> collection = new List<sObject>();

		@InvocableVariable(required=false)
		public String var01, var02, var03, var04, var05, var06, var07, var08, var09, var10,
					  var11, var12, var13, var14, var15, var16, var17, var18, var19, var20;

		@InvocableVariable(required=false)
		public Id contentDocumentId;

		@InvocableVariable(required=false)
		public Boolean isAttachmentInline = false;
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
			removeDuplicateRecipient(input);	// Avoid duplicate emails, as SendGrid will fail
			requestLogs.add(new SendGridRequestLog__c(TemplateId__c = input.templateId, HasAttachment__c = input.contentDocumentId != null, Request__c = JSON.serialize(input)));
		}

		INSERT requestLogs;
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

		SendGridEmail.post(event.RequestLogId__c, JSON.serialize(body).replace('from_email', 'from'));
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
		if (input.contentDocumentId == null) {
			return null;
		}

		ContentDocument contentDocument = [SELECT LatestPublishedVersionId FROM ContentDocument WHERE Id = :input.contentDocumentId];
		ContentVersion contentVersion = [SELECT Title, FileExtension, VersionData FROM ContentVersion WHERE Id = :contentDocument.LatestPublishedVersionId];
		Attachment attachment = new Attachment();
		attachment.filename = contentVersion.Title.containsIgnoreCase(contentVersion.FileExtension) ? contentVersion.Title : contentVersion.Title + '.' + contentVersion.FileExtension;
		attachment.content = EncodingUtil.base64Encode(contentVersion.VersionData);
		if (input.isAttachmentInline) {
			attachment.disposition = 'inline';
			attachment.content_id = 'inlineContent';
		}

		return new List<Attachment>{attachment};
	}

	private List<Personalization> setupPersonalizations(Input input) {
		List<Personalization> personalizations = new List<Personalization>();

		Map<String, Object> dynamicTemplateData = setupTemplateMergeFields(input);

		for (Integer i=0; i<input.toAddress.size(); i++) {
			Personalization personalization = new Personalization();
			personalization.to = new List<Email>{new Email(input.toAddress[i], input.toName[i])};
			personalization.dynamic_template_data = new Map<String, Object>(dynamicTemplateData);
			personalization.dynamic_template_data.put('fullName', input.toName[i]);
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
		private String subject;
	}

	private class Email {
		private String email;
		private String name;

		private Email(String email, String name) {
			this.email = email;
			this.name = name;
		}
	}
}