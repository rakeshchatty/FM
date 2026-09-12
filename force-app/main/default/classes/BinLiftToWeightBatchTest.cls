@isTest
public class BinLiftToWeightBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertVat();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null, 'FM0001');

		List<Product2> products = new List<Product2>();
		Product2 product1 = TestDataHelper.createProduct('Product 1', 'P0001', 'Collection');
		product1.ProductCategory__c = 'General Waste';
		product1.BinCategoryCode__c = 'GEN1100';
		products.add(product1);
		Product2 product2 = TestDataHelper.createProduct('Product 2', 'P0002', 'Collection');
		product2.ProductCategory__c = 'General Waste';
		product2.BinCategoryCode__c = 'GEN660';
		products.add(product2);
		INSERT products;
		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[0].Id, 65.00));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[1].Id, 95.00));
		INSERT pricebookEntries;

		Order order = TestDataHelper.createOrder(location.Id, null);
		order.IsBinCollection__c = true;
		order.Delivery_Date__c = System.today();
		INSERT order;

		List<OrderItem> orderItems = new List<OrderItem>();
		OrderItem orderItem1 = TestDataHelper.createOrderItem(order.Id, products[0].Id, pricebookEntries[0].Id);
		orderItem1.CollectionDate__c = System.today() - 1;
		orderItems.add(orderItem1);
		OrderItem orderItem2 = TestDataHelper.createOrderItem(order.Id, products[1].Id, pricebookEntries[1].Id);
		orderItem2.CollectionDate__c = System.today() - 1;
		orderItems.add(orderItem2);
		INSERT orderItems;
	}

	@isTest static void createBinWeightsAndProcessOrders() {

		List<OrderItem> orderItem = [SELECT Id, Order.AccountId FROM OrderItem];
		DateTime now = System.now() - 1;
		BinLift__c binLift1 = new BinLift__c(OrderProduct__c = orderItem[0].Id, Location__c = orderItem[0].Order.AccountId, LocationCode__c = 'FM0001', Kilogram__c = 100, WasteCategoryCode__c = 'GEN1100', TransponderCode__c = '43FD4C1400004000', ExternalId__c = '43FD4C1443FD4C100', Status__c = 'Matched', CollectedAt__c = now);
		INSERT binLift1;
		BinLift__c binLift2 = new BinLift__c(OrderProduct__c = orderItem[1].Id, Location__c = orderItem[1].Order.AccountId, LocationCode__c = 'FM0001', Kilogram__c = 90, WasteCategoryCode__c = 'GEN660', TransponderCode__c = '43FD4C1400005000', ExternalId__c = '43FD4C140043FD4C10', Status__c = 'Matched', CollectedAt__c = now);
		INSERT binLift2;

		Test.startTest();
		Database.executeBatch(new BinLiftToWeightBatch());
		Test.stopTest();

        Assert.areEqual(2, [SELECT Id FROM Weight__c].size());
	}
}