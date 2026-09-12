@IsTest
private class BinRentalChargeBatchTest {

	@TestSetup
	private static void setup() {
		Product2 rentalProduct = TestDataHelper.insertProduct('Rental Product', 'RP001', 'Collection');

		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 collectionProduct1 = TestDataHelper.insertProduct('Collection Product1', 'CP001', 'Collection', containerType.Id, rentalProduct.Id);
		Product2 collectionProduct2 = TestDataHelper.insertProduct('Collection Product2', 'CP002', 'Collection', containerType.Id, rentalProduct.Id);

		TestDataHelper.insertStandardPricebookEntry(rentalProduct.Id, 10);

		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct1 = TestDataHelper.insertSupplierProduct(supplier, collectionProduct1);
		Supplier_Product__c supplierProduct2 = TestDataHelper.insertSupplierProduct(supplier, collectionProduct2);

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Round__c round = TestDataHelper.insertRound();

		Schedule__c schedule1 = TestDataHelper.insertSchedule(location, round, supplier, supplierProduct1, '18:00');
		Schedule__c schedule2 = TestDataHelper.insertSchedule(location, round, supplier, supplierProduct2, '10:00');

		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);

		TestDataHelper.insertWaypoint(location, dispatch, dispatchLocation, schedule1.Id, supplierProduct1.Id, 5);
		TestDataHelper.insertWaypoint(location, dispatch, dispatchLocation, schedule2.Id, supplierProduct2.Id, 2);
	}

	@IsTest
	static void createsBinRentalOrderAndOrderItem() {
		Test.startTest();
		new BinRentalChargeSchedular().execute(null);
		Test.stopTest();

		List<Order> orders = [SELECT Id, Status FROM Order];
		Assert.areEqual(1, orders.size());

		List<OrderItem> orderItems = [SELECT Id, Quantity FROM OrderItem];
		Assert.areEqual(1, orderItems.size());
		Assert.areEqual(7, orderItems[0].Quantity);
	}

	@IsTest
	static void skipsLocationWithActiveRecurring() {
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' LIMIT 1];
		Supplier_Product__c sp = [SELECT Id, Supplier__c, Product__c FROM Supplier_Product__c LIMIT 1];
		TestDataHelper.insertRecurring(location.Id, sp.Product__c,  sp.Supplier__c);

		Test.startTest();
		new BinRentalChargeSchedular().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Count() FROM Order]);
	}

	@IsTest
	static void skipsBinRentalExemptAccount() {
		Account parent = [SELECT Id FROM Account WHERE RecordType.Name = 'Account'];

		parent.No_Bin_Rental__c = true;
		UPDATE parent;

		Test.startTest();
		new BinRentalChargeSchedular().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Count() FROM Order]);
	}

	@IsTest
	static void skipsAccountWithAccountManagerExemption() {
		Account parent = [SELECT Id FROM Account WHERE RecordType.Name = 'Account'];

		parent.Account_Manager__c = UserInfo.getUserId();
		UPDATE parent;

		Test.startTest();
		new BinRentalChargeSchedular().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Count() FROM Order]);
	}

	@IsTest
	static void skipsProductWithoutBinRentalProduct() {
		List<Product2> products = [SELECT Id FROM Product2 WHERE Name IN ('Collection Product1', 'Collection Product2')];
		for(Product2 p : products) {
			p.BinRentalProduct__c = null;
	 	}
		UPDATE products;

		Test.startTest();
		new BinRentalChargeSchedular().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Count() FROM Order]);
	}
}