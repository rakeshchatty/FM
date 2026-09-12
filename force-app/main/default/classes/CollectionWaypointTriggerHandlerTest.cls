@isTest
private class CollectionWaypointTriggerHandlerTest {

	@TestSetup
	static void setup() {
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

		Depot__c depot = [SELECT Id FROM Depot__c];
		Round__c round2 = TestDataHelper.createRound('Test Round 2', 2, depot, depot, false);
		INSERT round2;

        Test.startTest();
		Database.executebatch(new DispatchCreationBatch(), 5);
		Test.stopTest();
	}

	@isTest
	static void moveAllWaypoints() {
		List<DailyDispatch__c> dispatches = [SELECT Id FROM DailyDispatch__c ORDER BY RoundId__r.Name ASC];
        List<Collection_Waypoints__c> waypoints = [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id];
		for(Collection_Waypoints__c waypoint : waypoints) {
			waypoint.Daily_Dispatch__c = dispatches[1].Id;
		}

        Test.startTest();
        UPDATE waypoints;
        Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(0, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(waypoints.size(), [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[1].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[1].Id].size());
	}

	@isTest
	static void moveOneWaypoint() {
		List<DailyDispatch__c> dispatches = [SELECT Id FROM DailyDispatch__c ORDER BY RoundId__r.Name ASC];
		Collection_Waypoints__c waypoint = [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id LIMIT 1];
		waypoint.Daily_Dispatch__c = dispatches[1].Id;

        Test.startTest();
        UPDATE waypoint;
        Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(1, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[1].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[1].Id].size());
	}

	@isTest
	static void moveAllWaypointsExisting() {
		List<DailyDispatch__c> dispatches = [SELECT Id FROM DailyDispatch__c ORDER BY RoundId__r.Name ASC];
		TestDataHelper.insertDispatchLocation(dispatches[1], TestDataHelper.getLocation());

        List<Collection_Waypoints__c> waypoints = [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id];
		for(Collection_Waypoints__c waypoint : waypoints) {
			waypoint.Daily_Dispatch__c = dispatches[1].Id;
		}

		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[1].Id].size());

        Test.startTest();
        UPDATE waypoints;
        Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(0, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(2, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[1].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[1].Id].size());
	}

	@isTest
	static void moveOneWaypointsExisting() {
		List<DailyDispatch__c> dispatches = [SELECT Id FROM DailyDispatch__c ORDER BY RoundId__r.Name ASC];
		TestDataHelper.insertDispatchLocation(dispatches[1], TestDataHelper.getLocation());

		Collection_Waypoints__c waypoint = [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id LIMIT 1];
		waypoint.Daily_Dispatch__c = dispatches[1].Id;

		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[1].Id].size());

        Test.startTest();
        UPDATE waypoint;
        Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[0].Id].size());
		Assert.areEqual(1, [SELECT Id FROM Collection_Waypoints__c WHERE Daily_Dispatch__c = :dispatches[1].Id].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c WHERE Dispatch__c = :dispatches[1].Id].size());
	}
}