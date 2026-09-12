global without sharing class RoyalMailSftpEmailServiceBulk implements Messaging.InboundEmailHandler {

	private static final String WIRE_NUMBER = RoyalMailSetting__c.getOrgDefaults().WireNumber__c;

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

		List<Messaging.InboundEmail.BinaryAttachment> fileAttachments = getFileAttachment(email);

		if (fileAttachments == null || fileAttachments.isEmpty()) {
			return new Messaging.InboundEmailResult();
		}

		List<Attachment> attachments = new List<Attachment>();
		for (Messaging.InboundEmail.BinaryAttachment fileAttachment : fileAttachments) {
			String fileName = fileAttachment.fileName;

			DeliveryPackageTrackingFile__c trackingFile = new DeliveryPackageTrackingFile__c(FileName__c = fileName, Carrier__c = DeliveryPackage.CARRIER_ROYAL_MAIL);
			INSERT trackingFile;

			attachments.add(new Attachment(ParentId = trackingFile.Id, Name = fileName, Body = fileAttachment.body));
		}

		INSERT attachments;

		return new Messaging.InboundEmailResult();
	}

	private List<Messaging.InboundEmail.BinaryAttachment> getFileAttachment(Messaging.InboundEmail email) {
		if (email.binaryAttachments == null || email.binaryAttachments.isEmpty()) {
			return null;
		}

		List<Messaging.InboundEmail.BinaryAttachment> binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>();
		for (Messaging.InboundEmail.BinaryAttachment binaryAttachment : email.binaryAttachments) {
			if (binaryAttachment.fileName.startsWithIgnoreCase(WIRE_NUMBER)) {
				binaryAttachments.add(binaryAttachment);
			}
		}

		return binaryAttachments;
	}
}