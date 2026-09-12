@isTest
private class CollectionSuspendBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.suppressSuspensionDateValidation();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Round__c round = TestDataHelper.insertRound();
		TestDataHelper.insertSchedule(location, round, supplier, supplierProduct, '08:00');
	}

	@isTest
	static void activeSuspension() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__r.IsSuspended__c FROM Schedule__c LIMIT 1];
		Assert.isFalse(schedule.CollectionAggregator__r.IsSuspended__c);
		INSERT new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-5), ReactivationDate__c = System.today().addDays(5));

		Test.startTest();
		CollectionSuspendBatch.updateCollectionSuspendFlag();
		Test.stopTest();

		CollectionAggregator__c aggregator = [SELECT IsSuspended__c FROM CollectionAggregator__c WHERE Id = :schedule.CollectionAggregator__c];
		Assert.isTrue(aggregator.IsSuspended__c);
	}

	@isTest
	static void pastReactivation() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__c FROM Schedule__c LIMIT 1];
		UPDATE new CollectionAggregator__c(Id = schedule.CollectionAggregator__c, IsSuspended__c = true);
		CollectionAggregator__c aggregator  = [SELECT IsSuspended__c FROM CollectionAggregator__c WHERE Id = :schedule.CollectionAggregator__c];
		Assert.isTrue(aggregator.IsSuspended__c);
		INSERT new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-10), ReactivationDate__c = System.today());

		Test.startTest();
		CollectionSuspendBatch.updateCollectionSuspendFlag();
		Test.stopTest();

		aggregator = [SELECT IsSuspended__c FROM CollectionAggregator__c WHERE Id = :schedule.CollectionAggregator__c];
		Assert.isFalse(aggregator.IsSuspended__c);
	}

	@isTest
	static void futureSuspension() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__r.IsSuspended__c FROM Schedule__c LIMIT 1];
		Assert.isFalse(schedule.CollectionAggregator__r.IsSuspended__c);
		INSERT new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(10), ReactivationDate__c = System.today().addDays(20));

		Test.startTest();
		CollectionSuspendBatch.updateCollectionSuspendFlag();
		Test.stopTest();

		CollectionAggregator__c aggregator = [SELECT IsSuspended__c FROM CollectionAggregator__c WHERE Id = :schedule.CollectionAggregator__c];
		Assert.isFalse(aggregator.IsSuspended__c);
	}

	@isTest
	static void inactiveSuspension() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__r.IsSuspended__c FROM Schedule__c LIMIT 1];
		Assert.isFalse(schedule.CollectionAggregator__r.IsSuspended__c);
		INSERT new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-5), ReactivationDate__c = System.today().addDays(5), IsActive__c = false);

		Test.startTest();
		CollectionSuspendBatch.updateCollectionSuspendFlag();
		Test.stopTest();

		CollectionAggregator__c aggregator = [SELECT IsSuspended__c FROM CollectionAggregator__c WHERE Id = :schedule.CollectionAggregator__c];
		Assert.isFalse(aggregator.IsSuspended__c);
	}
}