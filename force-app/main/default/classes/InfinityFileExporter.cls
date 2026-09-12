public without sharing class InfinityFileExporter {

	private static final String FILE_HEADER = 'Trigger Title, Date & Time, Caller ID, Action';
	private static final InfinitySetting__c settings = InfinitySetting__c.getOrgDefaults();
	private static final Id ORG_WIDE_EMAIL_ID = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@thefirstmile.co.uk'].Id;

	private List<Opportunity> opportunities;

	public void export() {
		String csvContent = buildCsv();
		if (String.isBlank(csvContent)) {
			return;
		}

		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		String filename = 'Infinity-' + System.now().format('yyyyMMddHHmm') + '.csv';
		attachment.setFileName(filename);
		attachment.setContentType('text/csv');
		attachment.setBody(Blob.valueOf(csvContent));

		sendEmail(attachment);

		UPDATE opportunities;
	}

	private String buildCsv() {
		List<String> rows = getOpportunityRows();
		if (rows.isEmpty()) {
			return null;
		}
		rows.add(0, FILE_HEADER);
		return String.join(rows, '\n');
	}

	private List<String> getOpportunityRows() {
		opportunities = [SELECT Account.FinanceContact__r.Phone, CreatedDate
			FROM Opportunity WHERE CreatedDate = LAST_N_DAYS:1 AND IsSentToInfinity__c = false AND Type__c = 'Inbound Phone' AND Account.FinanceContact__r.Phone != null];

		List<String> rows = new List<String>();
		for (Opportunity opp : opportunities) {
			rows.add(formatCsv(opp.Id, opp.createdDate, opp.Account.FinanceContact__r?.Phone, 'New Opp'));
			opp.IsSentToInfinity__c = true;
		}
		return rows;
	}

	private String formatCsv(String opportunityID, DateTime createdDate, String phone, String callResult) {
		return String.join(new List<String>{opportunityID, createdDate.format('dd/MM/yyyy HH:mm', 'Europe/London'), normalizePhone(phone), callResult}, ',');
	}

	private void sendEmail(Messaging.EmailFileAttachment attachment) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ID);
		email.setToAddresses(new String[]{settings.ExternalInbox__c});
		email.setSubject('Infinity File Export');
		email.setPlainTextBody('Attached Infinity CSV file.');
		email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
	}

	private String normalizePhone(String phone) {
		if (String.isBlank(phone)) return '';
		String digitsOnly = phone.replaceAll('[^0-9]', '');
		return digitsOnly.right(10);
	}
}