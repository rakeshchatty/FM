@isTest
public class LiveLocationsTest {
	@testSetup static void testsetup() {
		Id locationRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
		Id accountRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
		Id pricebookId = Test.getStandardPricebookId();

		Account parent = new Account();
		parent.Name = 'firstmile - parent';
		parent.Industry = 'Other';
		parent.RecordTypeId = accountRecordTypeId;
		parent.Enqix_Dead_Live__c = 'Live';
		parent.Enqix_Date_Made_Live__c = system.today();
		parent.Price_Book__c = pricebookId;
		INSERT parent;

		Account partner = new Account();
		partner.Name = 'firstmile - partner';
		partner.Industry = 'Other';
		partner.RecordTypeId = partnerRecordTypeId;
		partner.Enqix_Dead_Live__c = 'Live';
		partner.Enqix_Date_Made_Live__c = system.today();
		partner.Price_Book__c = pricebookId;
		INSERT partner;

		Account location = new Account();
		location.Name = 'firstmile - location';
		location.Industry = 'Other';
		location.RecordTypeId = locationRecordTypeId;
		location.Enqix_Dead_Live__c = 'Live';
		location.Enqix_Date_Made_Live__c = system.today();
		location.Price_Book__c = pricebookId;
		location.parentId = parent.Id;
		location.Partnership__c = partner.Id;
		INSERT location;
	}

	@isTest static void testMethod1() {
		Account acc = [SELECT Id, ParentId, Partnership__c FROM Account WHERE Name = 'firstmile - location'];
		LiveLocations.Input input = new LiveLocations.Input();
		input.locationId = null;
		input.parentId = acc.parentId;
		input.partnershipId = acc.Partnership__c;
		List<LiveLocations.Output> output = LiveLocations.hasLiveLocations(new List<LiveLocations.Input>{input});
		system.assertEquals(output[0].doesParentHaveLiveLocations, true, 'Expecting parent to have live locations');
		system.assertEquals(output[0].doesPartnershipHaveLiveLocations, true, 'Expecting partner to have live locations');
	}

	@isTest static void testMethod2() {
		LiveLocations.Input input = new LiveLocations.Input();
		input.partnershipId = '123';
		input.parentId = '456';
		input.locationId = '987';
		LiveLocations.Output output = new LiveLocations.Output();
		output = LiveLocations.hasLiveLocations(input, 2, 1);
		system.assertEquals(output.doesParentHaveLiveLocations, true);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, false);

		output = LiveLocations.hasLiveLocations(input, 1, 2);
		system.assertEquals(output.doesParentHaveLiveLocations, false);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, true);

		output = LiveLocations.hasLiveLocations(input, 2, 2);
		system.assertEquals(output.doesParentHaveLiveLocations, true);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, true);

		output = LiveLocations.hasLiveLocations(input, 1, 1);
		system.assertEquals(output.doesParentHaveLiveLocations, false);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, false);
	}

	@isTest static void testMethod3() {
		LiveLocations.Input input = new LiveLocations.Input();
		input.partnershipId = '123';
		input.parentId = '123';
		input.locationId = '987';
		LiveLocations.Output output = new LiveLocations.Output();
		output = LiveLocations.hasLiveLocations(input, 1, 1);
		system.assertEquals(output.doesParentHaveLiveLocations, false);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, false);

		output = LiveLocations.hasLiveLocations(input, 2, 2);
		system.assertEquals(output.doesParentHaveLiveLocations, true);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, true);
	}

	@isTest static void testMethod4() {
		LiveLocations.Input input = new LiveLocations.Input();
		input.partnershipId = '123';
		input.parentId = '123';
		input.locationId = null;
		LiveLocations.Output output = new LiveLocations.Output();
		output = LiveLocations.hasLiveLocations(input, 1, 1);
		system.assertEquals(output.doesParentHaveLiveLocations, true);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, true);

		output = LiveLocations.hasLiveLocations(input, 0, 0);
		system.assertEquals(output.doesParentHaveLiveLocations, false);
		system.assertEquals(output.doesPartnershipHaveLiveLocations, false);
	}

	 @isTest static void testMethod5() {
		 Account account = [SELECT Id, ParentId, Partnership__c FROM Account WHERE Name = 'firstmile - location'];
		 Map<Id, Boolean> doesAccountHaveLiveLocations = LiveLocations.hasLiveLocations(new set<Id> {account.Partnership__c});
		 system.assertEquals(doesAccountHaveLiveLocations.get(account.Partnership__c), true);
	}
}