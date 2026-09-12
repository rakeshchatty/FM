public without sharing class ParcelforcePackageHandler {

	public void handleTrigger(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				sendShipment(newList);
				new DeliveryWaypoint().create(newList);
			}
			when AFTER_UPDATE {
				sendShipment(newList, oldMap);
				extractLabel(newList, oldMap);
				cancelShipment(newList, oldMap);
			}
		}
	}

	private static void sendShipment(List<DeliveryPackage__c> newList) {
		sendShipment(IdUtil.extractId(newList));
	}

	private static void sendShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (pkg.Status__c == DeliveryPackage.STATUS_RETRY && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_RETRY) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			sendShipment(packageIds);
		}
	}

	private static void sendShipment(Set<Id> packageIds) {
		Database.executeBatch(new DeliveryPackageShipmentBatch(packageIds), 40);
	}

	private static void extractLabel(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (!pkg.IsCollection__c && pkg.Status__c == DeliveryPackage.STATUS_ADVISED && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_ADVISED) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			Database.executeBatch(new DeliveryPackageLabelBatch(packageIds), 40);	// Maximum 100 callout allowed in single transaction.
		}
	}

	private static void cancelShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (!pkg.IsFinalStatus__c && pkg.Status__c == DeliveryPackage.STATUS_CANCEL_REQUEST && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_CANCEL_REQUEST) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			Database.executeBatch(new DeliveryPackageCancellationBatch(packageIds), 40);	// Providing 3 seconds for each callout. 40*3 = 120 seconds.
		}
	}
}