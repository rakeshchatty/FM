@isTest
public class BinWeightToWeightBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertCollectionServiceTimeSetting();
		TestDataHelper.insertVat();

		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 product = TestDataHelper.createProduct('Product 1', 'P0001', 'Collection');
		product.Container_Type__c = containerType.Id;
		INSERT product;
		TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);

		Round__c round = TestDataHelper.insertRound();
		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		List<Schedule__c> schedules = new List<Schedule__c>();
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00'));
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '09:00'));
		INSERT schedules;

		Test.startTest();
		new DispatchCreationScheduler().execute(null);
		Test.stopTest();
		new BinCollectionToOrderScheduler().execute(null);
	}

	@isTest static void createBinWeightsAndProcessOrders() {
		List<BinWeight__c> binWeights = new List<BinWeight__c>();
		for (Collection_Waypoints__c waypoint : [SELECT Id, Location__c, (SELECT Id FROM Order_Products__r LIMIT 1) FROM Collection_Waypoints__c]) {
			binWeights.add(new BinWeight__c(OrderProduct__c = waypoint.Order_Products__r[0].Id, Collection_Waypoint__c = waypoint.Id, Location__c = waypoint.Location__c, Kilogram__c = 100, CategoryCode__c = 'COFFE140', Date__c = System.now(), Status__c = 'Matched', CreatedDate = System.now() - 1));
		}
		INSERT binWeights;

		Test.startTest();
		Database.executeBatch(new BinWeightToWeightBatch());
		Test.stopTest();
		System.equals(2, [SELECT Id FROM Weight__c].size());
	}
}