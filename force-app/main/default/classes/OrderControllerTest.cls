@isTest
private class OrderControllerTest {
	@TestSetup
	static void testSetup() {
		TestDataHelper.insertVat();
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, Null);
		Account partner = TestDataHelper.insertPartner();

		TestDataHelper.insertContact(location.Id, 'Test');

		Suppliers__c firstMileSupplier = TestDataHelper.insertSupplierFirstMile();
		Suppliers__c externalSupplier = TestDataHelper.insertSupplier('External Supplier');

		List<Product2> products = new List<Product2>();
		products.add(TestDataHelper.createProduct('Product 1','P0001', 'Delivery', null));
		products.add(TestDataHelper.createProduct('Product 2','P0002', 'Delivery', null));
		products[1].IsVATExempt__c = true;
		products.add(TestDataHelper.createProduct('Product 3','P0003', 'Delivery', null));
		INSERT products;

		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		pricebookEntries.add(new PricebookEntry(Product2Id = products[0].Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 50, IsActive = True));
		pricebookEntries.add(new PricebookEntry(Product2Id = products[1].Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 70, IsActive = True));
		pricebookEntries.add(new PricebookEntry(Product2Id = products[2].Id, Pricebook2Id = Test.getStandardPricebookId(), UnitPrice = 100, IsActive = True));
		INSERT pricebookEntries;

		Subscribed_Products__c subscribedProduct = new Subscribed_Products__c(
			Account__c = location.Id,
			Product__c = products[1].Id,
			Supplier__c = externalSupplier.Id,
			Enqix_BID_Location_Limit_Quantity__c = 500,
			Enqix_ID__c = '1234555689'
		);
		INSERT subscribedProduct;

		INSERT new Supplier_Product__c(Supplier__c = externalSupplier.Id, Product__c = products[1].Id, Name = 'Test', MinimumOrderQuantity__c = 5);
		INSERT new Supplier_Product__c(Supplier__c = externalSupplier.Id, Product__c = products[2].Id, Name = 'Test', MinimumOrderQuantity__c = 3);

		Account_Discount__c disc = new Account_Discount__c();
		disc.Account__c = parent.id;
		disc.Product__c = products[1].Id;
		disc.DiscountSupStartDate__c = system.today().addDays(-1);
		disc.Product_Discount__c = 5;
		disc.BID_Price__c = 1;
		INSERT disc;

		Order order = TestDataHelper.insertOrder(location.Id);
		TestDataHelper.insertOrderItem(order.Id, products[1].Id, pricebookEntries[1].Id);
	}

	@isTest
	static void InitTestMethod() {
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location'];
		Test.startTest();
		orderController.init(location.Id);
		Test.stopTest();
	}

	@isTest
	static void addProductToCartTest() {
		Account location = [SELECT Name, ParentId, Partnership__c, Price_Book__c, Parent.PO_Required__c, IsVATExemptLocation__c, IsNational__c, Price_Book__r.isActive, Parent.Account_Service_Status__c, CurrencyIsoCode,
			Parent.Account_Discount__c, Parent.Direct_Debit_Discount__c, Parent.Enqix_Payment_Method__c, Enqix_Dead_Live__c, Parent.Enqix_Dead_Live__c FROM Account WHERE RecordType.Name = 'Location'];
		List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, Product2.Name, Product2.IsVATExempt__c, UnitPrice, Product2.Product_Category__r.Name FROM PricebookEntry WHERE Product2.Name IN ('Product 2', 'Product 3') ORDER BY Product2.Name];
		Suppliers__c externalSupplier = [SELECT Name FROM Suppliers__c WHERE IsExternal__c = true];

		Test.startTest();
		OrderController.addProductsToCart(new OrderController.ProductData(pricebookEntries[0], externalSupplier, 25), 'Available', null, new OrderController.Location(location));
		OrderController.addProductsToCart(new OrderController.ProductData(pricebookEntries[1], externalSupplier, 25), 'Subscribed', null, new OrderController.Location(location));
		Test.stopTest();
	}

	@isTest
	static void processAdditionalChargesTest() {
		AdditionalCharges.OrderData orderData = new AdditionalCharges.OrderData();
		AdditionalCharges.OrderItemData orderItem = new AdditionalCharges.OrderItemData();
		orderItem.productId = [SELECT Id FROM Product2 WHERE Name = 'Product 3'].Id;
		orderItem.quantity = 5;
		orderItem.unitPrice = 10;
		orderData.orderItems = new List<AdditionalCharges.OrderItemData>{orderItem};

		Test.startTest();
		OrderController.addAdditionalCharges(orderData);
		Test.stopTest();
	}

	@isTest
	static void saveOrderTest() {
		Account location = [SELECT Name, ParentId, Partnership__c, Price_Book__c, Parent.PO_Required__c, IsVATExemptLocation__c, IsNational__c, Price_Book__r.isActive, Parent.Account_Service_Status__c, CurrencyIsoCode,
			Parent.Account_Discount__c, Parent.Direct_Debit_Discount__c, Parent.Enqix_Payment_Method__c, Enqix_Dead_Live__c, Parent.Enqix_Dead_Live__c FROM Account WHERE RecordType.Name = 'Location'];
		List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, Product2.Name, UnitPrice, Product2.Product_Category__r.Name FROM PricebookEntry WHERE Product2.Name IN ('Product 2', 'Product 3') ORDER BY Product2.Name];
		Suppliers__c externalSupplier = [SELECT Id, Name FROM Suppliers__c WHERE IsExternal__c = true];

		Contact contact = [SELECT Id FROM Contact];

		OrderController.OrderData orderData = new OrderController.OrderData();
		orderData.locationId = location.Id;
		orderData.type = 'Regular';
		orderData.contactId = contact.Id;
		orderData.requestedDeliveryDate = String.valueOf(System.today());
		orderData.isPaymentConfirmed = true;
		orderData.priceBookId = location.Price_Book__c;
		orderData.orderItems = new List<OrderController.OrderItemData>();

		PricebookEntry pricebookEntry = [SELECT Id, Product2Id, Product2.Name, UnitPrice, Product2.Product_Category__r.Name FROM PricebookEntry WHERE Product2.Name = 'Product 2'];
		Account_Discount__c accountDiscount = [SELECT Id FROM Account_Discount__c];

		OrderController.OrderItemData orderItem = new OrderController.OrderItemData();
		orderItem.rowKey = 'test1';
		orderItem.productId = pricebookEntry.Product2Id;
		orderItem.pricebookEntryId = pricebookEntry.Id;
		orderItem.manualProductName = pricebookEntry.Product2.Name;
		orderItem.supplierId = externalSupplier.Id;
		orderItem.supplierName = externalSupplier.Name;
		orderItem.quantity = 25;
		orderItem.quantitySoldIn = 25;
		orderItem.listPrice = pricebookEntry.UnitPrice;
		orderItem.parentDiscount = 6;
		orderItem.partnerDiscount = 0;
		orderItem.discountToApply = 'Account';
		orderItem.parentDiscountId = accountDiscount.Id;
		orderData.orderItems.add(orderItem);

		Test.startTest();
		OrderController.saveOrder(orderData);
		Test.stopTest();

		Assert.areEqual(2, [SELECT Id FROM Order].size());
		Assert.areEqual(2, [SELECT Id FROM OrderItem].size());
	}
}