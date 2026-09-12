@isTest
public with sharing class CollectionScheduleCloneTest {
	@testSetup
	static void setup() {
		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Schedule__c schedule = TestDataHelper.insertSchedule(location, round, supplier, supplierProduct, '08:00');
	}

	@isTest
	static void CloneSchedule() {
		Schedule__c schedule = [Select Id FROM Schedule__c WHERE Time__c = '08:00' Limit 1];
		CollectionScheduleClone.clone(new List<Id>{schedule.Id});
	}

}