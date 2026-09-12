@isTest
public with sharing class SupplierServiceEmailTest {
	@testSetup
	static void setup() {
		TestDataHelper.suppressSuspensionDateValidation();
		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Schedule__c schedule = TestDataHelper.insertSchedule(location, round, supplier, supplierProduct, '08:00');
		Insert new Case(Type = 'General', Sub_Type__c = 'Other query', Subject = 'Test Case', Location__c = location.Id);
	}

	@isTest
	static void addAction() {
		Schedule__c schedule = [SELECT Location__c, Po_Number_Supplier__c FROM Schedule__c WHERE Time__c = '08:00' Limit 1];
		String caseId = [SELECT Id FROM Case WHERE Subject = 'Test Case' limit 1].Id;
		SupplierServiceEmail.Input input = new SupplierServiceEmail.Input();
		input.Action = 'Add';
		input.CaseId = caseId;
		input.PoNumber = schedule.Po_Number_Supplier__c;
		input.LocationId = schedule.Location__c;

		Test.startTest();
		SupplierServiceEmail.send(new List<SupplierServiceEmail.Input>{input});
		Test.stopTest();
	}

	@isTest
	static void amendAction() {
		Schedule__c schedule = [SELECT Location__c, Po_Number_Supplier__c FROM Schedule__c WHERE Time__c = '08:00' Limit 1];
		String caseId = [SELECT Id FROM Case WHERE Subject = 'Test Case' limit 1].Id;
		SupplierServiceEmail.Input input = new SupplierServiceEmail.Input();
		input.Action = 'Amend';
		input.CaseId = caseId;
		input.PoNumber = schedule.Po_Number_Supplier__c;
		input.LocationId = schedule.Location__c;

		Test.startTest();
		SupplierServiceEmail.send(new List<SupplierServiceEmail.Input>{input});
		Test.stopTest();
	}

	@isTest
	static void deleteAction() {
		Schedule__c schedule = [SELECT Location__c, Po_Number_Supplier__c FROM Schedule__c WHERE Time__c = '08:00' Limit 1];
		String caseId = [SELECT Id FROM Case WHERE Subject = 'Test Case' limit 1].Id;
		SupplierServiceEmail.Input input = new SupplierServiceEmail.Input();
		input.Action = 'Delete';
		input.CaseId = caseId;
		input.PoNumber = schedule.Po_Number_Supplier__c;
		input.LocationId = schedule.Location__c;

		Test.startTest();
		SupplierServiceEmail.send(new List<SupplierServiceEmail.Input>{input});
		Test.stopTest();
	}

	@isTest
	static void suspendAction() {
		Schedule__c schedule = [SELECT Location__c, Po_Number_Supplier__c, CollectionAggregator__c FROM Schedule__c WHERE Time__c = '08:00' Limit 1];

		INSERT new List<ScheduleSuspension__c> {
		new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today() - 1, ReactivationDate__c = System.today() + 5),
		new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today() + 10, ReactivationDate__c = System.today() + 15),
		new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today() + 20, ReactivationDate__c = System.today() + 25, IsActive__c = false)};

		String caseId = [SELECT Id FROM Case WHERE Subject = 'Test Case' limit 1].Id;
		SupplierServiceEmail.Input input = new SupplierServiceEmail.Input();
		input.Action = 'Suspend';
		input.CaseId = caseId;
		input.PoNumber = schedule.Po_Number_Supplier__c;
		input.LocationId = schedule.Location__c;

		Test.startTest();
		SupplierServiceEmail.send(new List<SupplierServiceEmail.Input>{input});
		Test.stopTest();
	}
}