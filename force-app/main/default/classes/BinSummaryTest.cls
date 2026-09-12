@isTest
private class BinSummaryTest {

	@isTest
	static void test() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null, 'FM0001');

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);

		Date yesterday = System.today() - 1;
		String month = String.valueOf('0' + yesterday.month()).right(2);
		String year = String.valueOf(yesterday.year());
        
		String key = Location.Id + '-' + 'GEN1100' + '-' +  year + '-' + month;

		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();
		Collection_Waypoints__c waypoint1 = TestDataHelper.createWaypoint(location, dispatch, dispatchLocation);
		waypoint1.Collection_Quantity__c = 5;
		waypoint1.CreatedDate = yesterday;
		waypoint1.BinKey__c = key;
		waypoints.add(waypoint1);
		Collection_Waypoints__c waypoint2 = TestDataHelper.createWaypoint(location, dispatch, dispatchLocation);
		waypoint2.Collection_Quantity__c = 7;
		waypoint2.CreatedDate = yesterday;
		waypoint2.BinKey__c = key;
		waypoints.add(waypoint2);
		INSERT waypoints;

		BinLift__c binLift1 = new BinLift__c(Location__c = location.Id, LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', CollectedAt__c = yesterday, WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, Key__c = key, Status__c = 'Matched');
		BinLift__c binLift2 = new BinLift__c(Location__c = location.Id, LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', CollectedAt__c = yesterday, WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, Key__c = key, Status__c = 'Matched');
		BinLift__c binLift3 = new BinLift__c(Location__c = location.Id, LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', CollectedAt__c = yesterday, WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, Key__c = key, Status__c = 'No match');
		BinLift__c binLift4 = new BinLift__c(Location__c = location.Id, LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', CollectedAt__c = yesterday, WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, Key__c = key, Status__c = 'No match');
		BinLift__c binLift5 = new BinLift__c(Location__c = location.Id, LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', CollectedAt__c = yesterday, WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, Key__c = key, Status__c = 'No match');
		INSERT new List<BinLift__c>{binLift1, binLift2, binLift3, binLift4, binLift5};

		Product2 product = TestDataHelper.insertProduct('General Collection', '123', 'Collection');
		product.BinCategoryCode__c = 'GEN1100';
		UPDATE product;

		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 1020);
		Order order = TestDataHelper.insertOrder(location.Id);
		OrderItem orderItem1 = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
		orderItem1.Quantity = 4;
		orderItem1.Collection_Waypoint__c = waypoint1.Id;
        orderItem1.CollectionDate__c = yesterday;
		orderItem1.BinKey__c = key;
		INSERT orderItem1;
		OrderItem orderItem2 = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
		orderItem2.Quantity = 2;
		orderItem2.Collection_Waypoint__c = waypoint2.Id;
        orderItem2.CollectionDate__c = yesterday;
		orderItem2.BinKey__c = key;
		INSERT orderItem2;

		Test.startTest();
		Database.executeBatch(new BinSummaryOfWaypointBatch());
		Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM BinSummary__c WHERE Month__c = :month AND Year__c = :year].size());
		Assert.areEqual(12, [SELECT Waypoints__c FROM BinSummary__c][0].Waypoints__c); //5 + 7 = 12
		Assert.areEqual(6, [SELECT OrderProducts__c FROM BinSummary__c][0].OrderProducts__c); //3 + 3 = 6
		Assert.areEqual(2, [SELECT BinMatched__c FROM BinSummary__c][0].BinMatched__c);
		Assert.areEqual(3, [SELECT BinUnmatched__c FROM BinSummary__c][0].BinUnmatched__c);
	}
}