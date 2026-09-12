@isTest
private class CollectionSuspendExtendBatchTest {

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
	static void extendToNextYear() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__c FROM Schedule__c LIMIT 1];
		ScheduleSuspension__c pastReactivationEveryYear = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-10), ReactivationDate__c = System.today().addDays(-1), IsEveryYear__c = true);
		ScheduleSuspension__c pastReactivationNotEveryYear = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-10), ReactivationDate__c = System.today().addDays(-1));
		ScheduleSuspension__c futureReactivationEveryYear = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-5), ReactivationDate__c = System.today().addDays(10), IsEveryYear__c = true);
		ScheduleSuspension__c futureSuspensionEveryYear = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(15), ReactivationDate__c = System.today().addDays(25), IsEveryYear__c = true);
		ScheduleSuspension__c inactivePastReactivationEveryYear = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = System.today().addDays(-30), ReactivationDate__c = System.today().addDays(-1), IsEveryYear__c = true, IsActive__c = false);
		INSERT new List<ScheduleSuspension__c>{pastReactivationEveryYear, pastReactivationNotEveryYear, futureReactivationEveryYear, futureSuspensionEveryYear, inactivePastReactivationEveryYear};

		Test.startTest();
		Database.executeBatch(new CollectionSuspendExtendBatch(), 1);
		Test.stopTest();

		Map<Id, ScheduleSuspension__c> suspensions = new Map<Id, ScheduleSuspension__c>([SELECT SuspensionDate__c, ReactivationDate__c FROM ScheduleSuspension__c]);
		pastReactivationEveryYear = suspensions.get(pastReactivationEveryYear.Id);
		Assert.areEqual(System.today().addDays(-10).addYears(1), pastReactivationEveryYear.SuspensionDate__c);
		Assert.areEqual(System.today().addDays(-1).addYears(1), pastReactivationEveryYear.ReactivationDate__c);

		pastReactivationNotEveryYear = suspensions.get(pastReactivationNotEveryYear.Id);
		Assert.areEqual(System.today().addDays(-10), pastReactivationNotEveryYear.SuspensionDate__c);
		Assert.areEqual(System.today().addDays(-1), pastReactivationNotEveryYear.ReactivationDate__c);

		futureReactivationEveryYear = suspensions.get(futureReactivationEveryYear.Id);
		Assert.areEqual(System.today().addDays(-5), futureReactivationEveryYear.SuspensionDate__c);
		Assert.areEqual(System.today().addDays(10), futureReactivationEveryYear.ReactivationDate__c);

		futureSuspensionEveryYear = suspensions.get(futureSuspensionEveryYear.Id);
		Assert.areEqual(System.today().addDays(15), futureSuspensionEveryYear.SuspensionDate__c);
		Assert.areEqual(System.today().addDays(25), futureSuspensionEveryYear.ReactivationDate__c);

		inactivePastReactivationEveryYear = suspensions.get(inactivePastReactivationEveryYear.Id);
		Assert.areEqual(System.today().addDays(-30), inactivePastReactivationEveryYear.SuspensionDate__c);
		Assert.areEqual(System.today().addDays(-1), inactivePastReactivationEveryYear.ReactivationDate__c);
	}
}