public without sharing class DeliveryPackageTrackingFileHandler {

	public void handleTrigger(List<DeliveryPackageTrackingFile__c> newList, Map<Id, DeliveryPackageTrackingFile__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				createEvents(newList);
			}
		}
	}

	private void createEvents(List<DeliveryPackageTrackingFile__c> newList) {
		List<DeliveryPackageTrackingFile__c> parcelforceList = filter(newList, DeliveryPackage.CARRIER_PARCELFORCE);
		if (!parcelforceList.isEmpty()) {
			ParcelforceTrackingFile.process(IdUtil.extractId(parcelforceList));
		}

		List<DeliveryPackageTrackingFile__c> royalMailList = filter(newList, DeliveryPackage.CARRIER_ROYAL_MAIL);
		if (!royalMailList.isEmpty()) {
			RoyalMailTrackingFile.process(IdUtil.extractId(royalMailList));
		}
	}

	private List<DeliveryPackageTrackingFile__c> filter(List<DeliveryPackageTrackingFile__c> trackingFiles, String carrier) {
		List<DeliveryPackageTrackingFile__c> filtered = new List<DeliveryPackageTrackingFile__c>();
		for (DeliveryPackageTrackingFile__c trackingFile : trackingFiles) {
			if (trackingFile.Carrier__c == carrier) {
				filtered.add(trackingFile);
			}
		}

		return filtered;
	}
}