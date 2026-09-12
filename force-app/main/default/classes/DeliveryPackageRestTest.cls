@isTest
private class DeliveryPackageRestTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();

		List<Account> locations = new List<Account>();
		locations.add(TestDataHelper.createLocation(parent.Id, null));
		locations[0].Name = 'London1';

		locations.add(TestDataHelper.createLocation(parent.Id, null));
		locations[1].Name = 'London2';
		locations[1].PriorityPackaging__c = true;
		INSERT locations;

		TestDataHelper.insertSupplier('First Mile Ltd');

		List<Order> orders = new List<Order>();
		// Non-priorty location
		orders.add(TestDataHelper.createOrder(locations[0].Id, Date.today() + 2));	// Expected sort index: 9
		orders.add(TestDataHelper.createOrder(locations[0].Id, Date.today() + 1));	// Expected sort index: 7
		orders.add(TestDataHelper.createOrder(locations[0].Id, Date.today()));		// Expected sort index: 7
		orders.add(TestDataHelper.createOrder(locations[0].Id, Date.today() - 1));	// Expected sort index: 6
		orders.add(TestDataHelper.createOrder(locations[0].Id, Date.today() - 2));	// Expected sort index: 5
		// Priorty location
		orders.add(TestDataHelper.createOrder(locations[1].Id, Date.today() + 2));	// Expected sort index: 4
		orders.add(TestDataHelper.createOrder(locations[1].Id, Date.today() + 1));	// Expected sort index: 3
		orders.add(TestDataHelper.createOrder(locations[1].Id, Date.today()));		// Expected sort index: 2
		orders.add(TestDataHelper.createOrder(locations[1].Id, Date.today() - 1));	// Expected sort index: 1
		orders.add(TestDataHelper.createOrder(locations[1].Id, Date.today() - 2));	// Expected sort index: 0

		for (Order order : orders) {
			order.Status = 'Confirmed';
		}
		INSERT orders;

		List<DeliveryPackage__c> packages = new List<DeliveryPackage__c>();
		for (Order order : orders) {
			packages.add(TestDataHelper.createDeliveryPackage(order.Id, DeliveryPackage.STATUS_LABELLED, order.Requested_Delivery_Date__c));
		}
		INSERT packages;
	}

	@isTest
	static void getPackages() {
		RestRequest req = new RestRequest();
		req.requestURI = '/services/apexrest/DeliveryPackage';
		req.httpMethod = 'GET';
		req.addParameter('size', 'Regular');
		RestContext.request = req;

		Assert.areEqual(10, DeliveryPackageRest.doGet().size());
	}

	@isTest
	static void lock() {
		RestRequest req = new RestRequest();
		req.requestURI = '/services/apexrest/DeliveryPackage';
		req.httpMethod = 'PATCH';
		req.addParameter('size', 'Regular');
		RestContext.request = req;

		DeliveryPackage__c expectedPackage;
		for (Integer i = 0; i < 10; i++) {
			expectedPackage = [SELECT Id FROM DeliveryPackage__c WHERE Status__c = :DeliveryPackage.STATUS_LABELLED
				ORDER BY Order__r.Account.PriorityPackaging__c DESC, Order__r.Requested_Delivery_Date__c, Order__r.OrderNumber LIMIT 1];

			Id lockedDeliveryPackageId = DeliveryPackageRest.lock();
			Assert.areEqual(expectedPackage.Id, lockedDeliveryPackageId, 'Unexpected locked delivery package Id');

			expectedPackage = [SELECT Status__c FROM DeliveryPackage__c WHERE Id = :lockedDeliveryPackageId];
			Assert.areEqual(DeliveryPackage.STATUS_LOCK, expectedPackage.Status__c, 'Status should be ' + DeliveryPackage.STATUS_LOCK);
		}

		Assert.isNull(DeliveryPackageRest.lock(), 'Unexpected locked delivery package Id');
	}

	static DeliveryPackage__c getNextExpectedPackage(String expectedStatus) {
		return [SELECT Id, Status__c FROM DeliveryPackage__c WHERE Status__c = :expectedStatus
			ORDER BY Order__r.Account.PriorityPackaging__c DESC, Order__r.Requested_Delivery_Date__c, Order__r.OrderNumber LIMIT 1];
	}
}