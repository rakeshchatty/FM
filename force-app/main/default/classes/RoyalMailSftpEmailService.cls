global without sharing class RoyalMailSftpEmailService implements Messaging.InboundEmailHandler {

	private static final String WIRE_NUMBER = RoyalMailSetting__c.getOrgDefaults().WireNumber__c;

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

		Messaging.InboundEmail.BinaryAttachment fileAttachment = getFileAttachment(email);
		if (fileAttachment == null) {
			return new Messaging.InboundEmailResult();
		}

		String fileName = fileAttachment.fileName;

		DeliveryPackageTrackingFile__c trackingFile = new DeliveryPackageTrackingFile__c(FileName__c = fileName, Carrier__c = DeliveryPackage.CARRIER_ROYAL_MAIL);
		INSERT trackingFile;

		Attachment attachment = new Attachment(ParentId = trackingFile.Id, Name = fileName, Body = fileAttachment.body);
		INSERT attachment;

		return new Messaging.InboundEmailResult();
	}

	private Messaging.InboundEmail.BinaryAttachment getFileAttachment(Messaging.InboundEmail email) {
		if (email.binaryAttachments == null || email.binaryAttachments.isEmpty()) {
			return null;
		}

		for (Messaging.InboundEmail.BinaryAttachment binaryAttachment : email.binaryAttachments) {
			if (binaryAttachment.fileName.startsWithIgnoreCase(WIRE_NUMBER)) {
				return binaryAttachment;
			}
		}

		return null;
	}
}