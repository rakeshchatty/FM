@RestResource(urlMapping='/DeliveryPackage/*')
global without sharing class DeliveryPackageRest {

	@HttpGet
	global static List<sObject> doGet() {
		String size = RestContext.request.params?.get('size');
		List<String> ALLOWED_STATUS = new List<String>{DeliveryPackage.STATUS_LABELLED, DeliveryPackage.STATUS_PACKAGED, DeliveryPackage.STATUS_LOCK};

		return [SELECT Id, OrderNumber, Account.Name, Account.PriorityPackaging__c, Requested_Delivery_Date__c,
				(SELECT Id, ProductName__c, Quantity, ExpectedQrCodeCount__c, IsQrCodeEnforced__c, (SELECT Id FROM QrCodes__r) FROM OrderItems),	// QrCodes__r is for showing the count on Packaged records
				(SELECT Id, Count__c, Carrier__c, Status__c, Size__c, (SELECT Id FROM Attachments) FROM DeliveryPackages__r
					WHERE Status__c IN :ALLOWED_STATUS ORDER BY CreatedDate DESC LIMIT 1)
			FROM Order
			WHERE Status = 'Confirmed' AND Id IN (SELECT Order__c FROM DeliveryPackage__c WHERE Status__c IN :ALLOWED_STATUS AND IsCollection__c = false AND Size__c = :size)
			ORDER BY Account.PriorityPackaging__c DESC, Requested_Delivery_Date__c, OrderNumber	// Priority true first and then by oldest RequestedDeliveryDate
			LIMIT 50000];
	}

	@HttpPatch
	global static Id lock() {
		String size = RestContext.request.params?.get('size');
		List<DeliveryPackage__c> packages = [SELECT Id FROM DeliveryPackage__c
			WHERE Status__c = :DeliveryPackage.STATUS_LABELLED AND IsCollection__c = false AND Order__r.Status = 'Confirmed' AND Size__c = :size
			ORDER BY Order__r.Account.PriorityPackaging__c DESC, Order__r.Requested_Delivery_Date__c, Order__r.OrderNumber LIMIT 20];
		if (packages.isEmpty()) {
			return null;
		}

		DeliveryPackage__c packageToLock;
		// Workaround to lock a record with speific sort order, as ORBER BY is not allowed with FOR UPDATE
		for (DeliveryPackage__c pkg : packages) {
			try {
				packageToLock = [SELECT Id FROM DeliveryPackage__c WHERE Id = :pkg.Id AND Status__c = :DeliveryPackage.STATUS_LABELLED FOR UPDATE];
			} catch (QueryException e) {
				continue;
			}

			packageToLock.Status__c = DeliveryPackage.STATUS_LOCK;
			UPDATE packageToLock;

			return packageToLock.Id;
		}

		return null;
	}
}