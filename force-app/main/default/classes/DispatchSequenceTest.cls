@isTest
private class DispatchSequenceTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);
	}

	@isTest
	static void sequenceMorningDispatches() {
		Round__c round = [SELECT Id FROM Round__c LIMIT 1];
		round.Round_Type__c = 'AM';
		UPDATE round;

		DispatchLocation__c dispatchLocation = [SELECT SequenceNumber__c FROM DispatchLocation__c LIMIT 1];
		Assert.isNull(dispatchLocation.SequenceNumber__c);

		Test.startTest();
		DispatchSequence.sequenceMorningDispatches();
		Test.stopTest();

		dispatchLocation = [SELECT SequenceNumber__c FROM DispatchLocation__c LIMIT 1];
		Assert.isNotNull(dispatchLocation.SequenceNumber__c);
	}

	@isTest
	static void sequenceEveningDispatches() {
		Round__c round = [SELECT Id FROM Round__c LIMIT 1];
		round.Round_Type__c = 'PM';
		UPDATE round;

		DispatchLocation__c dispatchLocation = [SELECT SequenceNumber__c FROM DispatchLocation__c LIMIT 1];
		Assert.isNull(dispatchLocation.SequenceNumber__c);

		Test.startTest();
		EveningDispatchSequence.sequence();
		Test.stopTest();

		dispatchLocation = [SELECT SequenceNumber__c FROM DispatchLocation__c LIMIT 1];
		Assert.isNotNull(dispatchLocation.SequenceNumber__c);
	}
}