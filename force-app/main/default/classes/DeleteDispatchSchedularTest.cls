@isTest
private class DeleteDispatchSchedularTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Round__c round = TestDataHelper.insertRound();

		DailyDispatch__c dispatch = new DailyDispatch__c(RoundId__c = round.Id, Name = round.Name);
		INSERT dispatch;
		Test.setCreatedDate(dispatch.Id, Datetime.now().addDays(-35));

		DispatchLocation__c dispatchLocation = new DispatchLocation__c(Dispatch__c = dispatch.Id, Location__c = location.Id);
		INSERT dispatchLocation;
		Test.setCreatedDate(dispatchLocation.Id, Datetime.now().addDays(-35));

		Collection_Waypoints__c waypoint = new Collection_Waypoints__c(Location__c = location.Id);
		INSERT waypoint;
		Test.setCreatedDate(waypoint.Id, Datetime.now().addDays(-35));
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