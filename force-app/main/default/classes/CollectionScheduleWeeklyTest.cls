@isTest
private class CollectionScheduleWeeklyTest {

	@testSetup
	static void setup() {
		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Schedule__c schedule = TestDataHelper.insertSchedule(location, round, supplier, supplierProduct, '08:00');
	}

	@isTest
	static void previousCollectionThisWeek() {
	  	Date currentWeekStart = Date.today().toStartOfWeek();

		Schedule__c schedule = [SELECT Id FROM Schedule__c LIMIT 1];
		schedule.WeekFrequency__c = '2';
		schedule.PreviousCollectionDate__c = currentWeekStart;
		UPDATE schedule;

		Test.startTest();
		new CollectionScheduleWeeklyScheduler().execute(null);
		Test.stopTest();

		schedule = [SELECT Week_Off__c FROM Schedule__c WHERE Id = :schedule.Id];
		Assert.isTrue(schedule.Week_Off__c);
	}

	@isTest
	static void nextCollectionNextWeek() {
		Date currentWeekStart = Date.today().toStartOfWeek();

		Schedule__c schedule = [SELECT Id FROM Schedule__c LIMIT 1];
		schedule.WeekFrequency__c = '2';
		schedule.PreviousCollectionDate__c = currentWeekStart.addDays(-7);
		UPDATE schedule;

		Test.startTest();
		new CollectionScheduleWeeklyScheduler().execute(null);
		Test.stopTest();

		schedule = [SELECT Week_Off__c FROM Schedule__c WHERE Id = :schedule.Id];
		Assert.isFalse(schedule.Week_Off__c);
	}
}