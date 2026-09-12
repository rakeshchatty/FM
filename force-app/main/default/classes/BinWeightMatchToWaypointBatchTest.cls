@isTest
private class BinWeightMatchToWaypointBatchTest {

	@isTest
	static void test() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		BinWeight__c bin1 = new BinWeight__c(Location__c = location.Id, CategoryCode__c = 'GEN1100', Kilogram__c = 100, Date__c = System.now() - 1);
		BinWeight__c bin2 = new BinWeight__c(Location__c = location.Id, CategoryCode__c = 'GEN1100', Kilogram__c = 100, Date__c = System.now() - 1);
		BinWeight__c bin3 = new BinWeight__c(Location__c = location.Id, CategoryCode__c = 'GEN1100', Kilogram__c = 100, Date__c = System.now() - 3);
		BinWeight__c bin4 = new BinWeight__c(Location__c = location.Id, CategoryCode__c = 'GEN1101', Kilogram__c = 100, Date__c = System.now() - 1);
		INSERT new List<BinWeight__c>{bin1, bin2, bin3, bin4};

		Product2 product = TestDataHelper.insertProduct('General Collection', '123', 'Collection');
		product.BinCategoryCode__c = 'GEN1100';
		UPDATE product;

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);
		Collection_Waypoints__c waypoint1 = TestDataHelper.insertWaypoint(location, dispatch, dispatchLocation);
		Collection_Waypoints__c waypoint2 = TestDataHelper.insertWaypoint(location, dispatch, dispatchLocation);

		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 1020);

		Order order = TestDataHelper.insertOrder(location.Id);
		OrderItem orderItem1 = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
		orderItem1.CollectionDate__c = System.today() - 1;
		orderItem1.Collection_Waypoint__c = waypoint1.Id;
		INSERT orderItem1;

		OrderItem orderItem2 = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
		orderItem2.CollectionDate__c = System.today() - 5;
		orderItem2.Collection_Waypoint__c = waypoint2.Id;
		INSERT orderItem2;

		Test.startTest();
		new BinWeightMatchToWaypointScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(null, [SELECT Collection_Waypoint__c FROM BinWeight__c WHERE Id = :bin4.Id].Collection_Waypoint__c);
		Assert.areEqual(orderItem1.Collection_Waypoint__c, [SELECT Collection_Waypoint__c FROM BinWeight__c WHERE Id = :bin1.Id].Collection_Waypoint__c);
		Assert.areEqual(orderItem1.Collection_Waypoint__c, [SELECT Collection_Waypoint__c FROM BinWeight__c WHERE Id = :bin2.Id].Collection_Waypoint__c);
		Assert.areEqual(orderItem2.Collection_Waypoint__c, [SELECT Collection_Waypoint__c FROM BinWeight__c WHERE Id = :bin3.Id].Collection_Waypoint__c);
	}
}