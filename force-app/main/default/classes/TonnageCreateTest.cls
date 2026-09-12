@isTest
private class TonnageCreateTest {

	@testSetup
	static void makeData() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		List<Round__c> rounds = new List<Round__c>();
		rounds.add(TestDataHelper.createRound('Test Round 1', 1, 'AM'));	// Both days
		rounds.add(TestDataHelper.createRound('Test Round 2', 2, 'PM'));	// Both days
		rounds.add(TestDataHelper.createRound('Test Round 3', 3, 'PM'));	// Previous day only
		INSERT rounds;

		Date today = Date.today();
		Date yesterday = today.addDays(-1);
		List<DailyDispatch__c> dispatches = new List<DailyDispatch__c>();
		dispatches.add(new DailyDispatch__c(RoundId__c = rounds[0].Id, Name = rounds[0].Name, Dispatch_Date__c = today));		// Current day
		dispatches.add(new DailyDispatch__c(RoundId__c = rounds[1].Id, Name = rounds[1].Name, Dispatch_Date__c = today));		// Current day
		dispatches.add(new DailyDispatch__c(RoundId__c = rounds[0].Id, Name = rounds[0].Name, Dispatch_Date__c = yesterday));	// Previous day
		dispatches.add(new DailyDispatch__c(RoundId__c = rounds[1].Id, Name = rounds[1].Name, Dispatch_Date__c = yesterday));	// Previous day
		dispatches.add(new DailyDispatch__c(RoundId__c = rounds[2].Id, Name = rounds[2].Name, Dispatch_Date__c = yesterday));	// Previous day
		dispatches.add(new DailyDispatch__c(RoundId__c = rounds[0].Id, Name = rounds[0].Name, Dispatch_Date__c = today.addDays(-10)));	// As 'default' dispatch
		INSERT dispatches;

		INSERT new TonnageSettings__c(DefaultDispatch__c = dispatches[5].Id);

		List<WeightronEvent__c> events = new List<WeightronEvent__c>();
		events.add(new WeightronEvent__c(Name = '1234-01', RoundNumber__c = 1, Net__c = 1000, DateOfTip__c = yesterday, TimeOfTip__c = Time.newInstance(6,0,0,0)));	// R1 - AM Previous Day
		events.add(new WeightronEvent__c(Name = '1234-02', RoundNumber__c = 1, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(6,0,0,0)));		// R1 - AM Current Day
		events.add(new WeightronEvent__c(Name = '1234-03', RoundNumber__c = 2, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(2,0,0,0)));		// R2 - PM Previous Day
		events.add(new WeightronEvent__c(Name = '1234-04', RoundNumber__c = 2, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(6,0,0,0)));		// R2 - PM Previous Day
		events.add(new WeightronEvent__c(Name = '1234-05', RoundNumber__c = 2, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(16,59,59,0)));	// R2 - PM Previous Day
		events.add(new WeightronEvent__c(Name = '1234-06', RoundNumber__c = 2, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(17,0,0,0)));	// R2 - PM Current Day
		events.add(new WeightronEvent__c(Name = '1234-07', RoundNumber__c = 3, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(2,0,0,0)));		// R3 - PM Previous Day
		events.add(new WeightronEvent__c(Name = '1234-08', RoundNumber__c = 3, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(21,0,0,0)));	// R3 - PM Previous Day
		events.add(new WeightronEvent__c(Name = '1234-09', RoundNumber__c = 3, Net__c = 1000, DateOfTip__c = yesterday, TimeOfTip__c = Time.newInstance(2,0,0,0)));	// R3 - PM Default Dispatch
		events.add(new WeightronEvent__c(Name = '1234-10', RoundNumber__c = 9, Net__c = 1000, DateOfTip__c = today, TimeOfTip__c = Time.newInstance(6,0,0,0)));		// Invalid Round 6 - Default Dispatch
		INSERT events;
	}

	@isTest
	static void testTonnageCreate() {
		Test.startTest();
		new TonnageCreateScheduler().execute(null);
		Test.stopTest();

		// Validate the created tonnage records and the dispatch date.
		Date today = Date.today();
		Assert.areEqual(2, [SELECT Id FROM Tonnage__c WHERE DailyDispatch__r.Dispatch_Date__c = :today.addDays(-10)].size());	// Default Dispatch
		Assert.areEqual(6, [SELECT Id FROM Tonnage__c WHERE DailyDispatch__r.Dispatch_Date__c = :today.addDays(-1)].size());	// Previous Day
		Assert.areEqual(2, [SELECT Id FROM Tonnage__c WHERE DailyDispatch__r.Dispatch_Date__c = :today].size());				// Current Day
	}

	@isTest
	static void testDeleteEvents() {
		List<WeightronEvent__c> events = [SELECT Id FROM WeightronEvent__c];
		Assert.areEqual(10, [SELECT Id FROM WeightronEvent__c].size());
		for (WeightronEvent__c event : events) {
			Test.setCreatedDate(event.Id, Datetime.now().addDays(-35));
		}

		Test.startTest();
		new DeleteWeightronEventSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM WeightronEvent__c].size());
	}
}