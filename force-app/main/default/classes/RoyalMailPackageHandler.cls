public without sharing class RoyalMailPackageHandler {

	public void handleTrigger(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				createShipment(newList);
				new DeliveryWaypoint().create(newList);
			}
			when AFTER_UPDATE {
				createShipment(newList, oldMap);
				cancelShipment(newList, oldMap);
				pickedShipment(newList, oldMap);
			}
		}
	}

	private static void createShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		List<DeliveryPackage__c> packages = new List<DeliveryPackage__c>();
		for (DeliveryPackage__c pkg : newList) {
			if (pkg.Status__c == DeliveryPackage.STATUS_RETRY && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_RETRY) {
				packages.add(pkg);
			}
		}
		if (!packages.isEmpty()) {
			createShipment(packages);
		}
	}

	private static void createShipment(List<DeliveryPackage__c> packages) {
		Set<Id> packageIds = IdUtil.extractId(packages);
		Database.executeBatch(new RoyalMailDeliveryCreateBatch(packageIds), 40);
	}

	private static void cancelShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (!pkg.IsFinalStatus__c && pkg.Status__c == DeliveryPackage.STATUS_CANCEL_REQUEST && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_CANCEL_REQUEST) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			Database.executeBatch(new RoyalMailDeliveryCancelBatch(packageIds), 40);	// Assuming 3 seconds for each callout. 40*3 = 120 seconds.
		}
	}

	private static void pickedShipment(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		Set<Id> packageIds = new Set<Id>();
		for (DeliveryPackage__c pkg : newList) {
			if (!pkg.IsFinalStatus__c && pkg.Status__c == DeliveryPackage.STATUS_PACKAGED && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_PACKAGED) {
				packageIds.add(pkg.Id);
			}
		}
		if (!packageIds.isEmpty()) {
			Database.executeBatch(new RoyalMailDeliveryPickedBatch(packageIds), 40);	// Assuming 3 seconds for each callout. 40*3 = 120 seconds.
		}
	}
}