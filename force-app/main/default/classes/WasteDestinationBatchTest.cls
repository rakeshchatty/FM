@isTest
private class WasteDestinationBatchTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Product2 product1 = TestDataHelper.createProduct('Product 1', 'P0001', 'Collection');
		product1.Service_Type__c = 'BATTERIES';
		product1.Service_Subtype__c = 'Liquid';
		INSERT product1;
		PricebookEntry pbe1 = TestDataHelper.insertStandardPricebookEntry(product1.Id, 10);

		Product2 product2 = TestDataHelper.insertProduct('Product 2', 'P0002', 'Collection');
		PricebookEntry pbe2 = TestDataHelper.insertStandardPricebookEntry(product2.Id, 10);

		Facility__c facility = TestDataHelper.insertFacility('Facility');
		TestDataHelper.insertWasteDestination(facility.Id, Date.today().addDays(-30), Date.today().addDays(30), 'BATTERIES', 'Liquid');

		Order order = TestDataHelper.insertOrder(location.Id);
		OrderItem orderItem1 = TestDataHelper.createOrderItem(order.Id, product1.Id, pbe1.Id);
		orderItem1.Facility__c = facility.Id;
		INSERT orderItem1;
		OrderItem orderItem2 = TestDataHelper.createOrderItem(order.Id, product2.Id, pbe2.Id);
		orderItem2.Facility__c = facility.Id;
		INSERT orderItem2;
	}

	@isTest
	static void wasteDestinationUpdated() {

		Test.startTest();
		Database.executeBatch(new WasteDestinationBatch());
		Test.stopTest();

		Assert.areEqual(1, [SELECT Count() FROM OrderItem WHERE WasteDestination__c != null]);
		Assert.areEqual(1, [SELECT Count() FROM OrderItem WHERE WasteDestination__c = null]);
	}
}