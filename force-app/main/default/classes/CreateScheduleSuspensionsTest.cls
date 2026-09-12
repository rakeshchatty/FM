@isTest
private class CreateScheduleSuspensionsTest {
    
    @testSetup
    static void setUp() {
        TestDataHelper.insertCollectionServiceTimeSetting();

		Round__c round = TestDataHelper.insertRound();
		Product2 product = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
        List<Schedule__c> schedules = new List<Schedule__c>();
		Schedule__c schedule1 = TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00');
        schedule1.Days__c = 'Monday;Tuesday;Wednesday';
		schedules.add(schedule1);
        Schedule__c schedule2 = TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '10:00');
        schedule2.Days__c = 'Monday;Tuesday;Wednesday';
        schedules.add(schedule2);
        INSERT schedules;

        Id aggregatorId = [SELECT CollectionAggregator__c FROM Schedule__c WHERE Time__c = '08:00' LIMIT 1].CollectionAggregator__c;

        List<ScheduleSuspension__c> scheduleSuspensions = new List<ScheduleSuspension__c>();
        scheduleSuspensions.add(TestDataHelper.createScheduleSuspension(aggregatorId, Date.today().addDays(1), Date.today().addDays(5)));
        scheduleSuspensions.add(TestDataHelper.createScheduleSuspension(aggregatorId, Date.today().addDays(10), Date.today().addDays(15)));
        INSERT scheduleSuspensions;
    }

    @isTest
    static void test() {
        Id aggregatorId = [SELECT CollectionAggregator__c FROM Schedule__c WHERE Time__c = '08:00' LIMIT 1].CollectionAggregator__c;

        CreateScheduleSuspensions.input input = new CreateScheduleSuspensions.input();
        input.amendedAggregatorId = aggregatorId;
        input.newSchedules = [SELECT Id FROM Schedule__c WHERE Time__c = '10:00'];

        Test.startTest();
        CreateScheduleSuspensions.create(new List<CreateScheduleSuspensions.Input>{input});
        Test.stoptest();

        Assert.areEqual(2, [SELECT COUNT() FROM ScheduleSuspension__c WHERE Aggregator__r.Time__c = '10:00']);
    }
}