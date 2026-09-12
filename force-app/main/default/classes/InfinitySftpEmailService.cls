global with sharing class InfinitySftpEmailService implements Messaging.InboundEmailHandler {

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
		Messaging.InboundEmail.BinaryAttachment sftpFileAttachment = getSftpFileAttachment(email);
		if (sftpFileAttachment == null) {
			return new Messaging.InboundEmailResult();
		}

		List<String> lines = sftpFileAttachment.body.toString().split('\n');
		if (lines.size() <= 1) {
			return new Messaging.InboundEmailResult();
		}
		lines.remove(0); // Remove header

		List<Opportunity> opportunities = new List<Opportunity>();
		for (String line : lines) {
			if (String.isBlank(line)) {
				continue;
			}

			List<String> fieldValues = StringUtil.splitTrim(line, ',');
			if (String.isBlank(fieldValues[1])) {
				continue;
			}
			Integer fieldCount = fieldValues.size();
			opportunities.add(new Opportunity(Id = fieldValues[1],
				gaconnector_First_Click_Channel__c = fieldValues[0],
				gaconnector_First_Click_Campaign__c = fieldCount < 3 ? null : fieldValues[2],
				gaconnector_First_Click_Medium__c = fieldCount < 4 ? null : fieldValues[3] == 'ppc' ? 'cpc' : fieldValues[3],
				gaconnector_First_Click_Landing_Page__c = fieldCount < 5 ? null : fieldValues[4].left(255),
				gaconnector_First_Click_Term__c = fieldCount < 6 ? null : fieldValues[5]));
		}

		UPDATE opportunities;

		return new Messaging.InboundEmailResult();
	}

	private Messaging.InboundEmail.BinaryAttachment getSftpFileAttachment(Messaging.InboundEmail email) {
		if (email.binaryAttachments == null || email.binaryAttachments.isEmpty()) {
			return null;
		}

		return email.binaryAttachments[0];
	}
}