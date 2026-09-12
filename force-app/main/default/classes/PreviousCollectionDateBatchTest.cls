@isTest
private class PreviousCollectionDateBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertCollectionServiceTimeSetting();

		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Schedule__c schedule = TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00');
        schedule.PreviousCollectionDate__c = Date.today().addDays(-15);
		INSERT schedule;
	}

	@isTest
	static void updatePreviousCollectionDate() {
		Test.startTest();
		Database.executeBatch(new PreviousCollectionDateBatch());
		Test.stopTest();

		Assert.isTrue(System.today().addDays(-6) < [SELECT NextCollectionDate__c FROM Schedule__c WHERE Time__c = '08:00' LIMIT 1].NextCollectionDate__c);
	}

    @isTest
	static void computeDateWithWeekFrequencyTwo() {
		Assert.isTrue(System.today().addDays(-3) < new PreviousCollectionDateBatch().computePreviousCollectionDate(System.today().addDays(-15), 2));
	}

    @isTest
	static void computeDateWithWeekFrequencyThree() {
		Assert.isTrue(System.today().addDays(-20) < new PreviousCollectionDateBatch().computePreviousCollectionDate(System.today().addDays(-15), 3));
	}
}