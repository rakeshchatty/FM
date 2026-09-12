public without sharing class RoyalMailTrackingFile {

	private List<DeliveryPackageTrackingEvent__c> trackingEvents = new List<DeliveryPackageTrackingEvent__c>();

	@future
	public static void process(Set<Id> trackingFileId) {
		new RoyalMailTrackingFile().createTrackingEvents([SELECT Body, ParentId FROM Attachment WHERE ParentId IN :trackingFileId]);
	}

	private void createTrackingEvents(List<Attachment> attachments) {
		for (Attachment attachment : attachments) {
			createTrackingEvents(attachment);
		}

		if (!trackingEvents.isEmpty()) {
			INSERT trackingEvents;
		}
	}

	private void createTrackingEvents(Attachment attachment) {
		for (String line : attachment.Body.toString().replace('\n', '\r\n').split('\r\n')) {
			// Skip Header and Trailer lines. Process only the Detail 'D' lines.
			if (line.startsWithIgnoreCase('D')) {
				List<String> fields = StringUtil.splitTrimStrip(line, ',', '"');
				if (fields.size() > 9) {
					trackingEvents.add(createTrackingEvent(attachment.ParentId, fields));
				}
			}
		}
	}

	private DeliveryPackageTrackingEvent__c createTrackingEvent(Id trackingFileId, List<String> fields) {
		Datetime eventDateTime = Datetime.newInstanceGmt(Integer.valueOf(fields[8].substring(0, 4)),
													  Integer.valueOf(fields[8].substring(4, 6)),
													  Integer.valueOf(fields[8].substring(6, 8)),
													  Integer.valueOf(fields[9].substring(0, 2)),
													  Integer.valueOf(fields[9].substring(2, 4)),
													  Integer.valueOf(fields[9].substring(4, 6))
													 );

		DeliveryPackageTrackingEvent__c trackingEvent = new DeliveryPackageTrackingEvent__c(File__c = trackingFileId, Name = fields[2], Code__c = fields[6], DateTime__c = eventDateTime, Carrier__c = DeliveryPackage.CARRIER_ROYAL_MAIL);
		return trackingEvent;
	}
}