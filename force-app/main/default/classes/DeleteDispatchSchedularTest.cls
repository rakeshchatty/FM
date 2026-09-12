@isTest
private class DeleteDispatchSchedularTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Round__c round = TestDataHelper.insertRound();

		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		Test.setCreatedDate(dispatch.Id, Datetime.now().addDays(-95));

		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);
		Test.setCreatedDate(dispatchLocation.Id, Datetime.now().addDays(-95));

		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Product2 product = TestDataHelper.insertProduct('Test Product 01', 'TP001', 'Collection');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);

		Schedule__c schedule = TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '10:00');
		schedule.Start_Date__c = Date.today().addDays(-105);
		schedule.End_Date__c = Date.today().addDays(-95);
		INSERT schedule;
		Test.setCreatedDate(schedule.Id, Datetime.now().addDays(-95));

		Collection_Waypoints__c waypoint = new Collection_Waypoints__c(Location__c = location.Id);
		INSERT waypoint;
		Test.setCreatedDate(waypoint.Id, Datetime.now().addDays(-95));
	}

	@isTest
	static void deletion() {
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c LIMIT 1];
		DispatchLocation__c dispatchLocation = [SELECT Id FROM DispatchLocation__c LIMIT 1];
		Collection_Waypoints__c waypoint = [SELECT Id FROM Collection_Waypoints__c LIMIT 1];

		Test.startTest();
		new DeleteDispatchSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(1, [SELECT Id FROM DailyDispatch__c].size());
		Assert.areEqual(0, [SELECT Id FROM DispatchLocation__c].size());
		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c].size());
	}
}