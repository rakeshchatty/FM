@isTest
public class BinCollectionOverweightChargeBatchTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertVat();
		TestDataHelper.insertSupplier('First Mile Ltd');

		Account parentAccount = TestDataHelper.insertAccount();

		Account location = TestDataHelper.createLocation(parentAccount.Id, null);
		location.Price_Book__c = Test.getStandardPricebookId();
		INSERT location;

		Account chargeExcludedLocation = TestDataHelper.createLocation(parentAccount.Id, null);
		chargeExcludedLocation.No_Overweight_Charges__c = true;
		chargeExcludedLocation.Price_Book__c = Test.getStandardPricebookId();
		INSERT chargeExcludedLocation;

		Suppliers__c externalSupplier = TestDataHelper.insertSupplier('External Supplier Name');

		Product_Category__c gwProductCategory = TestDataHelper.insertProductCategory('General Waste GW');
		Product_Category__c dmrProductCategory = TestDataHelper.insertProductCategory('Mixed Recycling DMR');
		Product_Category__c fdProductCategory = TestDataHelper.insertProductCategory('Food');
		Product_Category__c glsProductCategory = TestDataHelper.insertProductCategory('Glass');

		List<Product2> chargeProducts = new List<Product2>();
		chargeProducts.add(TestDataHelper.createProduct('General Waste Overweight Charge Product', 'GWOVERWT', 'Collection'));
		chargeProducts.add(TestDataHelper.createProduct('Mixed Recycling Overweight Charge Product', 'DMROVERWT', 'Collection'));
		chargeProducts.add(TestDataHelper.createProduct('Food Overweight Charge Product', 'FOODOVERWT', 'Collection'));
		chargeProducts.add(TestDataHelper.createProduct('Glass Overweight Charge Product', 'GLASSOVER', 'Collection'));
		INSERT chargeProducts;

		List<Product2> products = new List<Product2>();
		products.add(TestDataHelper.createProduct('Test Product 01', 'TP001', 'Collection', gwProductCategory.Id));
		products[0].OverweightChargeProduct__c = chargeProducts[0].Id;
		products[0].KG__c = 51;

		products.add(TestDataHelper.createProduct('Test Product 02', 'TP002', 'Collection', dmrProductCategory.Id));
		products[1].OverweightChargeProduct__c = chargeProducts[1].Id;
		products[1].KG__c = 72;

		products.add(TestDataHelper.createProduct('Test Product 03', 'TP003', 'Collection', fdProductCategory.Id));
		products[2].OverweightChargeProduct__c = chargeProducts[2].Id;
		products[2].KG__c = 45;

		products.add(TestDataHelper.createProduct('Test Product 01', 'TP004', 'Collection', glsProductCategory.Id));
		products[3].OverweightChargeProduct__c = chargeProducts[3].Id;
		products[3].KG__c = 60;

		INSERT products;

		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[0].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[1].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[2].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[3].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(chargeProducts[0].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(chargeProducts[1].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(chargeProducts[2].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(chargeProducts[3].Id, 10));
		INSERT pricebookEntries;

		List<Order> orders = new List<Order>();
		Order order1 = TestDataHelper.createOrder(location.Id, null);
		order1.IsBinCollection__c = true;
		order1.Delivery_Date__c = System.today();
		orders.add(order1);

		Order order2 = TestDataHelper.createOrder(location.Id, null);
		order2.IsBinCollection__c = true;
		order2.Delivery_Date__c = System.today().addDays(-1);
		orders.add(order2);

		Order order3 = TestDataHelper.createOrder(location.Id, null);
		order3.IsBinCollection__c = true;
		order3.Delivery_Date__c = System.today().addDays(-2);
		orders.add(order3);

		Order order4 = TestDataHelper.createOrder(location.Id, null);
		order4.IsBinCollection__c = true;
		order4.Delivery_Date__c = System.today().addDays(-3);
		orders.add(order4); //External Supplier order

		Order order5 = TestDataHelper.createOrder(chargeExcludedLocation.Id, null);
		order5.IsBinCollection__c = true;
		order5.Delivery_Date__c = System.today().addDays(-4);
		orders.add(order5); //Excluded location

		INSERT orders;

		List<OrderItem> orderItems = new List<OrderItem>();
		orderItems.add(TestDataHelper.createOrderItem(order1.Id, products[0].Id, pricebookEntries[0].Id));
		orderItems.add(TestDataHelper.createOrderItem(order1.Id, products[1].Id, pricebookEntries[1].Id));
		///////////////////////////////////////////////////////////////////////////////////////////////////////
		orderItems.add(TestDataHelper.createOrderItem(order2.Id, products[0].Id, pricebookEntries[0].Id));
		orderItems.add(TestDataHelper.createOrderItem(order2.Id, products[1].Id, pricebookEntries[1].Id));
		///////////////////////////////////////////////////////////////////////////////////////////////////////
		orderItems.add(TestDataHelper.createOrderItem(order3.Id, products[0].Id, pricebookEntries[0].Id));
		orderItems.add(TestDataHelper.createOrderItem(order3.Id, products[1].Id, pricebookEntries[1].Id));
		///////////////////////////////////////////////////////////////////////////////////////////////////////
		orderItems.add(TestDataHelper.createOrderItem(order4.Id, products[0].Id, pricebookEntries[0].Id));
		orderItems[6].Supplier__c = externalSupplier.Id;
		orderItems.add(TestDataHelper.createOrderItem(order4.Id, products[1].Id, pricebookEntries[1].Id));
		orderItems[7].Supplier__c = externalSupplier.Id;
		///////////////////////////////////////////////////////////////////////////////////////////////////////
		orderItems.add(TestDataHelper.createOrderItem(order5.Id, products[0].Id, pricebookEntries[0].Id));
		orderItems.add(TestDataHelper.createOrderItem(order5.Id, products[1].Id, pricebookEntries[1].Id));

		orderItems.add(TestDataHelper.createOrderItem(order1.Id, products[2].Id, pricebookEntries[2].Id));
		orderItems.add(TestDataHelper.createOrderItem(order1.Id, products[3].Id, pricebookEntries[3].Id));
		INSERT orderItems;

        List<Weight__c> weights = new List<Weight__c>();
        weights.add(new Weight__c(Order_Product__c = orderItems[0].Id, Total_KG_Per_Unit__c = 56)); // Excess GW: 56 - 51 = 5
        weights.add(new Weight__c(Order_Product__c = orderItems[1].Id, Total_KG_Per_Unit__c = 75)); // Excess DMR: 75 - 72 = 3
        weights.add(new Weight__c(Order_Product__c = orderItems[1].Id, Total_KG_Per_Unit__c = 79)); // Excess DMR: 79 - 72 = 7
        weights.add(new Weight__c(Order_Product__c = orderItems[2].Id, Total_KG_Per_Unit__c = 75)); // Excess GW: 75 - 51 = 24
        weights.add(new Weight__c(Order_Product__c = orderItems[2].Id, Total_KG_Per_Unit__c = 77)); // Excess GW: 77 - 51 = 26
        weights.add(new Weight__c(Order_Product__c = orderItems[3].Id, Total_KG_Per_Unit__c = 100)); // Excess DMR: 100 - 72 = 28
        weights.add(new Weight__c(Order_Product__c = orderItems[3].Id, Total_KG_Per_Unit__c = 119)); // Excess DMR: 119 - 72 = 45
        weights.add(new Weight__c(Order_Product__c = orderItems[4].Id, Total_KG_Per_Unit__c = 50)); // Excess GW: 50 - 52 = 0
        weights.add(new Weight__c(Order_Product__c = orderItems[4].Id, Total_KG_Per_Unit__c = 50)); // Excess GW: 50 - 52 = 0
        weights.add(new Weight__c(Order_Product__c = orderItems[5].Id, Total_KG_Per_Unit__c = 72)); // Excess DMR: 72 - 72 = 0
        weights.add(new Weight__c(Order_Product__c = orderItems[5].Id, Total_KG_Per_Unit__c = 72)); // Excess DMR: 72 - 72 = 0
        weights.add(new Weight__c(Order_Product__c = orderItems[6].Id, Total_KG_Per_Unit__c = 90)); // Excess GW: 90 - 51 = 39
        weights.add(new Weight__c(Order_Product__c = orderItems[6].Id, Total_KG_Per_Unit__c = 112)); // Excess GW: 112 - 51 = 61
        weights.add(new Weight__c(Order_Product__c = orderItems[7].Id, Total_KG_Per_Unit__c = 144)); // Excess DMR: 144 - 72 = 72
        weights.add(new Weight__c(Order_Product__c = orderItems[7].Id, Total_KG_Per_Unit__c = 200)); // Excess DMR: 200 - 72 = 128
        weights.add(new Weight__c(Order_Product__c = orderItems[8].Id, Total_KG_Per_Unit__c = 100)); // Excess GW: 100 - 51 = 49
        weights.add(new Weight__c(Order_Product__c = orderItems[8].Id, Total_KG_Per_Unit__c = 92)); // Excess GW: 92 - 51 = 90
        weights.add(new Weight__c(Order_Product__c = orderItems[9].Id, Total_KG_Per_Unit__c = 110)); // Excess DMR: 110 - 72 = 38
        weights.add(new Weight__c(Order_Product__c = orderItems[9].Id, Total_KG_Per_Unit__c = 124)); // Excess DMR: 124 - 72 = 52

        weights.add(new Weight__c(Order_Product__c = orderItems[10].Id, Total_KG_Per_Unit__c = 80)); // Excess FD: 80 - 45 = 35
        weights.add(new Weight__c(Order_Product__c = orderItems[11].Id, Total_KG_Per_Unit__c = 124)); // Excess GLS: 124 - 60 = 64
        INSERT weights;
	}

	@isTest
	static void testExecute() {
		Test.startTest();
		new BinCollectionOverweightChargeScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(05.00, [SELECT Quantity FROM OrderItem WHERE Product2.ProductCode = 'GWOVERWT' AND Order.Delivery_Date__c = :System.today()].Quantity);
		Assert.areEqual(10.00, [SELECT Quantity FROM OrderItem WHERE Product2.ProductCode = 'DMROVERWT' AND Order.Delivery_Date__c = :System.today()].Quantity);
		Assert.areEqual(50.00, [SELECT Quantity FROM OrderItem WHERE Product2.ProductCode = 'GWOVERWT' AND Order.Delivery_Date__c = :System.today().addDays(-1)].Quantity);
		Assert.areEqual(75.00, [SELECT Quantity FROM OrderItem WHERE Product2.ProductCode = 'DMROVERWT' AND Order.Delivery_Date__c = :System.today().addDays(-1)].Quantity);

		Assert.areEqual(35.00, [SELECT Quantity FROM OrderItem WHERE Product2.ProductCode = 'FOODOVERWT' AND Order.Delivery_Date__c = :System.today()].Quantity);
		Assert.areEqual(64.00, [SELECT Quantity FROM OrderItem WHERE Product2.ProductCode = 'GLASSOVER' AND Order.Delivery_Date__c = :System.today()].Quantity);

		Assert.areEqual(2, [SELECT Id FROM Order WHERE Delivery_Date__c = :System.today()].size());
		Assert.areEqual(2, [SELECT Id FROM Order WHERE Delivery_Date__c = :System.today().addDays(-1)].size());
		Assert.areEqual(1, [SELECT Id FROM Order WHERE Delivery_Date__c = :System.today().addDays(-2)].size());

		Assert.areEqual(2, [SELECT Id FROM Order WHERE Delivery_Date__c = :System.today().addDays(-3)].size());
		Assert.areEqual(1, [SELECT Id FROM Order WHERE Delivery_Date__c = :System.today().addDays(-4)].size());
	}
}