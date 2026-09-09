public without sharing class DeliveryPackageTrakingFileTriggerHandler {

	public void handleTrigger(List<DeliveryPackageTrackingFile__c> newList, Map<Id, DeliveryPackageTrackingFile__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				createEvents(newList);
			}
		}
	}

	private static void createEvents(List<DeliveryPackageTrackingFile__c> newList) {
		DeliveryPackageTrackingFile.process(IdUtil.extractId(newList));
	}
}