@isTest
private class LocationFirstCollectionDateBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertCollectionServiceTimeSetting();

		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		List<Schedule__c> schedules = new List<Schedule__c>();
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00'));
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '09:00'));
		INSERT schedules;
	}

	@isTest
	static void firstCollectionDateUpdate() {
		Test.startTest();
		new DispatchCreationScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(System.today() + 1, [SELECT FirstCollectionDate__c FROM Account WHERE Name = 'Location'].FirstCollectionDate__c);
	}
}