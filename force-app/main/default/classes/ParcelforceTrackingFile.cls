public without sharing class ParcelforceTrackingFile {

	private List<DeliveryPackageTrackingEvent__c> trackingEvents = new List<DeliveryPackageTrackingEvent__c>();

	@future
	public static void process(Set<Id> trackingFileId) {
		new ParcelforceTrackingFile().createTrackingEvents([SELECT Body, ParentId FROM Attachment WHERE ParentId IN :trackingFileId]);
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
		for (String line : attachment.Body.toString().split('\n')) {
			trackingEvents.add(createTrackingEvent(attachment.ParentId, line));
		}
	}

	private DeliveryPackageTrackingEvent__c createTrackingEvent(Id trackingFileId, String line) {
		List<String> fields = line.split('\\+');
		Integer currentYear = System.today().year();
		Integer eventYear = Integer.valueOf((currentYear / 100) + fields[6].substring(0, 2));
		if (eventYear != currentYear) {
			eventYear = currentYear - 1;	// Assuming year is always current year or previous year, not any other value.
		}
		Datetime eventDateTime = Datetime.newInstance(Integer.valueOf(eventYear),
													  Integer.valueOf(fields[6].substring(2, 4)),
													  Integer.valueOf(fields[6].substring(4, 6)),
													  Integer.valueOf(fields[7].substring(0, 2)),
													  Integer.valueOf(fields[7].substring(2, 4)),
													  Integer.valueOf(fields[7].substring(4, 6))
													 );

		DeliveryPackageTrackingEvent__c trackingEvent = new DeliveryPackageTrackingEvent__c(File__c = trackingFileId, Name = fields[4], Code__c = fields[5], DateTime__c = eventDateTime, Carrier__c = DeliveryPackage.CARRIER_PARCELFORCE);
		return trackingEvent;
	}
}