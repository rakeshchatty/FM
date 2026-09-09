global without sharing class DeliveryPackageSftpEmailService implements Messaging.InboundEmailHandler {

	private static final String WIRE_NUMBER = ParcelforceSetting__c.getOrgDefaults().WireNumber__c;

	global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {

		Messaging.InboundEmail.BinaryAttachment sftpFileAttachment = getSftpFileAttachment(email);
		if (sftpFileAttachment == null) {
			return new Messaging.InboundEmailResult();
		}

		String fileName = sftpFileAttachment.fileName;

		DeliveryPackageTrackingFile__c trackingFile = new DeliveryPackageTrackingFile__c(FileName__c = fileName);
		INSERT trackingFile;

		Attachment attachment = new Attachment(ParentId = trackingFile.Id, Name = fileName, Body = sftpFileAttachment.body);
		INSERT attachment;

		return new Messaging.InboundEmailResult();
	}

	private Messaging.InboundEmail.BinaryAttachment getSftpFileAttachment(Messaging.InboundEmail email) {
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