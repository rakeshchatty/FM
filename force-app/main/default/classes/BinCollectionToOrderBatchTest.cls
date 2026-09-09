@isTest
private class BinCollectionToOrderBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertCollectionServiceTimeSetting();

		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 product = TestDataHelper.createProduct('Product 1', 'P0001', 'Collection');
		product.Container_Type__c = containerType.Id;
		INSERT product;
		TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);

		Round__c round = TestDataHelper.insertRound();
		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		List<Schedule__c> schedules = new List<Schedule__c>();
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00'));
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '09:00'));
		INSERT schedules;

		// Create dispatches and waypoints
		new DispatchCreationScheduler().execute(null);

		TestDataHelper.insertVat();
	}

	@isTest static void createBinOrders() {
		Test.startTest();
		new BinCollectionToOrderScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM Order].size());
		Assert.areEqual(2, [SELECT Id FROM OrderItem].size());
	}
}