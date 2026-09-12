@isTest
private class ClusterSequenceBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertCollectionServiceTimeSetting();

		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location1 = TestDataHelper.insertLocation(parent.Id, null);
		Account location2 = TestDataHelper.createLocation(parent.Id, null);
		location2.StreetSegmentID__c = '40689764024';
		INSERT location2;
		Account location3 = TestDataHelper.createLocation(parent.Id, null);
		location3.StreetSegmentID__c = '40689764024';
		INSERT location3;
		List<Schedule__c> schedules = new List<Schedule__c>();
		schedules.add(TestDataHelper.createSchedule(location1, round, supplier, supplierProduct, '08:00'));
		schedules.add(TestDataHelper.createSchedule(location2, round, supplier, supplierProduct, '09:00'));
		schedules.add(TestDataHelper.createSchedule(location3, round, supplier, supplierProduct, '09:00'));
		INSERT schedules;

		Test.startTest();
		new DispatchCreationScheduler().execute(null);
		Test.stopTest();
	}

	@isTest
	static void clusterTest() {
		Id dailyDispatch = [SELECT Id FROM DailyDispatch__c LIMIT 1].Id;
		Test.startTest();
		Database.executeBatch(new ClusterSequenceBatch(new Set<Id>{dailyDispatch}), 1);
		Test.stopTest();

		Assert.areEqual(3, [SELECT Id, SequenceNumber__c FROM DispatchLocation__c WHERE SequenceNumber__c != null].size());
		Assert.areEqual(2, [SELECT Id, SequenceNumber__c FROM DispatchLocation__c WHERE Location__r.StreetSegmentId__c = '40689764024'].size());
	}
}