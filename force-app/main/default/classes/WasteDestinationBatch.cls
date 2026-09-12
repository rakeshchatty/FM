public without sharing class WasteDestinationBatch implements Database.Batchable<SObject> {

	public Database.QueryLocator start(Database.BatchableContext bc) {
		return Database.getQueryLocator([SELECT Id, Facility__c, WasteDestination__c, Product2.Service_Type__c, Product2.Service_Subtype__c FROM OrderItem WHERE Facility__c != null AND WasteDestination__c = null AND CreatedDate = TODAY]);
	}

	public void execute(Database.BatchableContext bc, List<OrderItem> scope) {
		Map<Id, List<WasteDestination__c>> facilityToWasteDestinationsMap = new Map<Id, List<WasteDestination__c>>();

		for (OrderItem orderItem : scope) {
			if (orderItem.Facility__c != null && !facilityToWasteDestinationsMap.containsKey(orderItem.Facility__c)) {
				facilityToWasteDestinationsMap.put(orderItem.Facility__c, new List<WasteDestination__c>());
			}
		}

		if (!facilityToWasteDestinationsMap.isEmpty()) {
			for (WasteDestination__c wasteDestination : [SELECT Facility__c, ServiceType__c, ServiceSubtype__c FROM WasteDestination__c WHERE Facility__c IN :facilityToWasteDestinationsMap.keySet() AND IsActiveToday__c = true]) {
				facilityToWasteDestinationsMap.get(wasteDestination.Facility__c).add(wasteDestination);
			}
		}

		List<OrderItem> orderItemsToUpdate = new List<OrderItem>();
		for (OrderItem orderItem : scope) {
			if (orderItem.Facility__c != null) {
				for (WasteDestination__c wasteDestination : facilityToWasteDestinationsMap.get(orderItem.Facility__c)) {
					if (orderItem.Product2.Service_Type__c == wasteDestination.ServiceType__c && orderItem.Product2.Service_Subtype__c == wasteDestination.ServiceSubtype__c) {
						orderItemsToUpdate.add(new OrderItem(Id = orderItem.Id, WasteDestination__c = wasteDestination.Id));
						break;
					}
				}
			}
		}

		if (!orderItemsToUpdate.isEmpty()) {
			Database.SaveResult[] results = Database.update(orderItemsToUpdate, false);
			LogRegister.createLogsUpsert(results, orderItemsToUpdate, 'Set Waste Destination', 'Update', 'OrderItem', 'OrderId');
		}
	}

	public void finish(Database.BatchableContext bc) {}
}