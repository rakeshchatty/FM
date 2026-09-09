@isTest
public with sharing class MissedCollectionHandlerTest {

	@testSetup
	static void makeData() {
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Round__c round = TestDataHelper.insertRound();
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		List<Schedule__c> schedules = new List<Schedule__c>();
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00'));
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '09:00'));
		INSERT schedules;

		INSERT new DailyDispatch__c(RoundId__c = round.Id, Name = 'Test dispatch');
	}

	@isTest
	static void checkWithoutMissedCollection() {
		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c].size());
		Assert.areEqual(0, [SELECT Id FROM DispatchLocation__c].size());
		updateCase(false);
		Assert.areEqual(1, [SELECT Id FROM Collection_Waypoints__c].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c].size());
	}

	@isTest
	static void checkWaypointAndDispatchLocation() {
		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c].size());
		Assert.areEqual(0, [SELECT Id FROM DispatchLocation__c].size());
		updateCase(true);
		Assert.areEqual(2, [SELECT Id FROM Collection_Waypoints__c].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c].size());
	}

	@isTest
	static void checkWaypoint() {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c LIMIT 1];
		INSERT new DispatchLocation__c(Dispatch__c = dispatch.Id, Location__c = location.Id);

		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c].size());
		updateCase(true);
		Assert.areEqual(2, [SELECT Id FROM Collection_Waypoints__c].size());
		Assert.areEqual(1, [SELECT Id FROM DispatchLocation__c].size());
	}

	static void updateCase(Boolean withMissedCollections) {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		Case missedCase = new Case(
			RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Missed Collection').getRecordTypeId(),
			Type = 'Missed Collection',
			AccountId = location.Id,
			Location__c = location.Id,
			Sub_Type__c = 'Collection Round Service Missed'
		);
		INSERT missedCase;

		if (withMissedCollections) {
			List<Missed_Collection__c> missedCollections = new List<Missed_Collection__c>();
			for (Schedule__c schedule : [SELECT Id FROM Schedule__c WHERE Location__c = :location.Id AND Days__c = :System.now().format('EEEE')]) {
				missedCollections.add(new Missed_Collection__c(Case__c = missedCase.Id, Collection_Schedule__c = schedule.Id));
			}
			INSERT missedCollections;
		}

		missedCase.Round_Dispatched__c = [SELECT Id FROM DailyDispatch__c LIMIT 1].Id;
		Assert.areEqual(0, [SELECT Id FROM Collection_Waypoints__c].size());

		Test.startTest();
		UPDATE missedCase;
		Test.stopTest();
	}
}