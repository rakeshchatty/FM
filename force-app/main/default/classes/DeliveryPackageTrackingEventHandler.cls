public without sharing class DeliveryPackageTrackingEventHandler {

	public void handleTrigger(List<DeliveryPackageTrackingEvent__c> newList, Map<Id, DeliveryPackageTrackingEvent__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				processEvents(newList);
			}
		}
	}

	private void processEvents(List<DeliveryPackageTrackingEvent__c> newList) {
		List<DeliveryPackageTrackingEvent__c> parcelforceList = filter(newList, DeliveryPackage.CARRIER_PARCELFORCE);
		if (!parcelforceList.isEmpty()) {
			new ParcelforceTrackingEvent().process(parcelforceList);
		}

		List<DeliveryPackageTrackingEvent__c> royalMailList = filter(newList, DeliveryPackage.CARRIER_ROYAL_MAIL);
		if (!royalMailList.isEmpty()) {
			new RoyalMailTrackingEvent().process(royalMailList);
		}
	}

	private List<DeliveryPackageTrackingEvent__c> filter(List<DeliveryPackageTrackingEvent__c> events, String carrier) {
		List<DeliveryPackageTrackingEvent__c> filtered = new List<DeliveryPackageTrackingEvent__c>();
		for (DeliveryPackageTrackingEvent__c event : events) {
			if (event.Carrier__c == carrier) {
				filtered.add(event);
			}
		}

		return filtered;
	}
}