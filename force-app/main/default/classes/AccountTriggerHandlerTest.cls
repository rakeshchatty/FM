@isTest
public class AccountTriggerHandlerTest {

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
		location.Enqix_Dead_Live__c = 'live';
		location.Enqix_Date_Made_Live__c = system.today();
		location.Price_Book__c = pricebookId;
		location.parentId = parent.Id;
		location.Partnership__c = partner.Id;
		INSERT location;
	}

	@isTest static void testMethod1() {
        CodeOperation.setCodeOperation();
		Account parent = [SELECT Id FROM Account WHERE Name = 'firstmile - parent'];
		parent.Enqix_Dead_Live__c = 'Dead';
		parent.Enqix_ReasonMarkedDead__c = 'Other';
		parent.Enqix_Date_Made_Dead__c = system.today();
		parent.Price_Book__c = null;
		try {
			UPDATE parent;
		} catch(Exception e) {
			System.assertEquals(e.getMessage().contains('Cannot be dead as account has live location.'), true);
		}
        CodeOperation.setUserOperation();
		System.assertEquals(false, CodeOperation.isCodeOperation());
	}

	@isTest static void testMethod2() {
        CodeOperation.setCodeOperation();
		System.assertEquals(true, CodeOperation.isCodeOperation());
		Account partner = [SELECT Id FROM Account WHERE Name = 'firstmile - partner'];
		partner.Enqix_Dead_Live__c = 'Dead';
		partner.Enqix_Date_Made_Dead__c = system.today();
		partner.Price_Book__c = null;
		try {
			UPDATE partner;
		} catch(Exception e) {
			System.assertEquals(e.getMessage().contains('Cannot be dead as account has live location.'), true);
		}
        
	}
}