public without sharing class DeliveryPackageTriggerHandler {

	public void handleTrigger(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap, TriggerOperation operation) {
		List<DeliveryPackage__c> parcelforceList = filter(newList, DeliveryPackage.CARRIER_PARCELFORCE);
		if (!parcelforceList.isEmpty()) {
			new ParcelforcePackageHandler().handleTrigger(parcelforceList, oldMap, operation);
		}

		List<DeliveryPackage__c> royalMailList = filter(newList, DeliveryPackage.CARRIER_ROYAL_MAIL);
		if (!royalMailList.isEmpty()) {
			new RoyalMailPackageHandler().handleTrigger(royalMailList, oldMap, operation);
		}

		List<DeliveryPackage__c> firstMileList = filter(newList, DeliveryPackage.CARRIER_FIRST_MILE);
		if (!firstMileList.isEmpty()) {
			new FirstMilePackageHandler().handleTrigger(firstMileList, oldMap, operation);
		}
	}

	private List<DeliveryPackage__c> filter(List<DeliveryPackage__c> packages, String carrier) {
		List<DeliveryPackage__c> filtered = new List<DeliveryPackage__c>();
		for (DeliveryPackage__c pkg : packages) {
			if (pkg.Carrier__c == carrier) {
				filtered.add(pkg);
			}
		}

		return filtered;
	}
}