public without sharing class FirstMilePackageHandler {

	public void handleTrigger(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				createShipment(newList);
				new DeliveryWaypoint().create(newList);
			}
			when AFTER_UPDATE {
				createShipment(newList, oldMap);
				extractLabel(newList, oldMap);
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

	private static void createShipment(List<DeliveryPackage__c> newList) {
		List<DeliveryPackage__c> packages = new List<DeliveryPackage__c>();
		for (DeliveryPackage__c pkg : newList) {
			packages.add(new DeliveryPackage__c(Id = pkg.Id, Status__c = DeliveryPackage.STATUS_ADVISED, Message__c = ''));
		}
		UPDATE packages;
	}

	private static void extractLabel(List<DeliveryPackage__c> newList, Map<Id, DeliveryPackage__c> oldMap) {
		List<DeliveryPackage__c> packages = new List<DeliveryPackage__c>();
		for (DeliveryPackage__c pkg : newList) {
			if (!pkg.IsCollection__c && pkg.Status__c == DeliveryPackage.STATUS_ADVISED && oldMap.get(pkg.Id).Status__c != DeliveryPackage.STATUS_ADVISED) {
				packages.add(pkg);
			}
		}
		if (!packages.isEmpty()) {
			Database.executeBatch(new FirstMileDeliveryLabelBatch(packages), 50);
		}
	}
}