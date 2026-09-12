@isTest
public class AdvanceBinCollectionToOrderBatchTest {

	@testSetup
	private static void setup() {
		TestDataHelper.suppressSuspensionDateValidation();
		Product2 rentalProduct = TestDataHelper.insertProduct('Rental Product', 'RP001', 'Collection');

		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 product1 = TestDataHelper.insertProduct('Test Product', '12355321', 'Collection', containerType.Id, rentalProduct.Id);

		TestDataHelper.insertStandardPricebookEntry(rentalProduct.Id, 10);
		TestDataHelper.insertStandardPricebookEntry(product1.Id, 10);

		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct1 = TestDataHelper.insertSupplierProduct(supplier, product1);

		Account parent = TestDataHelper.createAccount();
		parent.MonthsInvoicedInAdvance__c = '3';
		parent.NextAdvanceInvoiceDate__c = Date.today().toStartOfMonth().addMonths(1);
		INSERT parent;
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Round__c round = TestDataHelper.insertRound();

		TestDataHelper.insertSchedule(location, round, supplier, supplierProduct1, '18:00');
	}

	@isTest
	static void validateDatesWithoutSuspension() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__c, Start_Date__c, End_Date__c, Days__c, Week_Off__c, WeekFrequency__c, PreviousCollectionDate__c FROM Schedule__c WHERE Days__c = 'Monday'];
		schedule.Start_Date__c = schedule.End_Date__c = null;

		Test.startTest();
		AdvanceBinCollectionToOrderBatch batch = new AdvanceBinCollectionToOrderBatch();
		batch.loadAggregatorToSuspensionsMap(new List<Schedule__c>{schedule});
		Set<Date> dates = batch.getCollectionDates(schedule);
		Test.stopTest();
		Assert.areEqual(13, dates.size());
	}

	@isTest
	static void validateDatesWithSuspension() {
		Schedule__c schedule = [SELECT Id, CollectionAggregator__c, Start_Date__c, End_Date__c, Days__c, Week_Off__c, WeekFrequency__c, PreviousCollectionDate__c FROM Schedule__c WHERE Days__c = 'Monday'];

		Date startDate = Date.today().toStartOfMonth().addMonths(1);
		ScheduleSuspension__c suspension1 = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = startDate, ReactivationDate__c = startDate.addDays(7));
		ScheduleSuspension__c suspension2 = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = startDate.AddMonths(1), ReactivationDate__c = startDate.AddMonths(1).addDays(7));
		ScheduleSuspension__c suspension3 = new ScheduleSuspension__c(Aggregator__c = schedule.CollectionAggregator__c, SuspensionDate__c = startDate.AddMonths(2), ReactivationDate__c = startDate.AddMonths(2).addDays(7));
		INSERT new List<ScheduleSuspension__c>{suspension1, suspension2, suspension3};

		schedule.Start_Date__c = schedule.End_Date__c = null;

		Test.startTest();
		AdvanceBinCollectionToOrderBatch batch = new AdvanceBinCollectionToOrderBatch();
		batch.loadAggregatorToSuspensionsMap(new List<Schedule__c>{schedule});
		Set<Date> dates = batch.getCollectionDates(schedule);
		Test.stopTest();
		Assert.areEqual(10, dates.size());
	}

	@isTest
	static void test() {
		Account parent = [SELECT NextAdvanceInvoiceDate__c FROM Account WHERE RecordType.Name = 'Account'];

		Test.startTest();
		new AdvanceBinCollectionToOrderSchedular().execute(null);
		Test.stopTest();

		Assert.areEqual(2, [SELECT Count() FROM Order]);

		Id rentalProductId = [SELECT Id FROM Product2 WHERE Name = 'Rental Product'].Id;
		Assert.areEqual(1, [SELECT Count() FROM OrderItem WHERE Product2Id = :rentalProductId]);
		Assert.areEqual(6, [SELECT Quantity FROM OrderItem WHERE Product2Id = :rentalProductId].Quantity);

		Assert.areEqual(parent.NextAdvanceInvoiceDate__c.addMonths(3), [SELECT NextAdvanceInvoiceDate__c FROM Account WHERE RecordType.Name = 'Account'].NextAdvanceInvoiceDate__c);
	}
}