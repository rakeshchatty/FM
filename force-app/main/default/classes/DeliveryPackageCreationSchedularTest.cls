@isTest
private class DeliveryPackageCreationSchedularTest {

	private static final Decimal LONDON_LAT = 51.74;
	private static final Decimal LONDON_LON = 00.32;
	private static final Decimal INNER_LONDON_LAT = 51.51;
	private static final Decimal INNER_LONDON_LON = -0.09;
	private static final Decimal NON_LONDON_LAT = 51.48;
	private static final Decimal NON_LONDON_LON = -1.88;

	@testSetup
	static void setup() {
		TestDataHelper.insertParcelforceSetting();
		TestDataHelper.insertSupplier('First Mile Ltd');
		Depot__c depot = TestDataHelper.insertDepot();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Contact contact = TestDataHelper.insertContact(parent.Id, 'SomeName');
		TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');

		List<Product2> products = new List<Product2>();
		products.add(TestDataHelper.createProduct('Test Name0', 'Test Code1', 'Delivery'));
		products.add(TestDataHelper.createProduct('Test Name1', 'Test Code2', 'Delivery'));
		products.add(TestDataHelper.createProduct('Test Name2', 'Test Code3', 'Delivery'));
		products.add(TestDataHelper.createProduct('Test Name3', 'Test Code4', 'Collection'));
		products[0].IsDeliveryByExternalCarrier__c = products[1].IsDeliveryByExternalCarrier__c = products[2].IsDeliveryByExternalCarrier__c = products[3].IsDeliveryByExternalCarrier__c = true;
		products[1].PackageBoxCount__c = 3;
		products[2].PackageBoxCount__c = 5;
		products[3].IsCollection__c = true;
		products[3].CollectionDepot__c = depot.Id;
		INSERT products;

		List<PricebookEntry> pbes = new List<PricebookEntry>();
		for (Product2 product : products) {
			pbes.add(TestDataHelper.createStandardPricebookEntry(product.Id, 10.00));
		}
		INSERT pbes;
	}

	@isTest
	static void createPackage() {
		createOrders(LONDON_LAT, LONDON_LON, 2);

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(2, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void createPackageBeyondMax() {
		createOrders(LONDON_LAT, LONDON_LON, TestDataHelper.MAX_ORDERS_PER_DAY_LONDON + 1);

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(TestDataHelper.MAX_ORDERS_PER_DAY_LONDON, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void createPackageBeyondMin() {
		createOrders(LONDON_LAT, LONDON_LON, 2);
		createOrders(INNER_LONDON_LAT, INNER_LONDON_LON, TestDataHelper.MIN_ORDERS_PER_DAY_LONDON + 1);

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(3, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void createPackageNonLondon() {
		createOrders(NON_LONDON_LAT, NON_LONDON_LON, TestDataHelper.MAX_ORDERS_PER_DAY_NON_LONDON + 1);

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(TestDataHelper.MAX_ORDERS_PER_DAY_NON_LONDON, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void retainBikeOrders() {
		createOrders(INNER_LONDON_LAT, INNER_LONDON_LON, TestDataHelper.MIN_ORDERS_PER_DAY_LONDON + 1);

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(1, [SELECT Id FROM DeliveryPackage__c].size());
	}

    @isTest
    static void countPackageBoxes() {
		createOrders(LONDON_LAT, LONDON_LON, 1);

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(26, [SELECT Count__c FROM DeliveryPackage__c].Count__c);
    }

	@isTest
	static void createCollectionPackage() {
		createCollectionOrder();

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock(true));
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(1, [SELECT Id FROM DeliveryPackage__c].size());
	}

	static void createOrders(Decimal shippingLatitude, Decimal shippingLongitude, Integer count) {
		Account location = TestDataHelper.getLocation();
		List<Product2> products = TestDataHelper.getProducts();
		PricebookEntry pbe0 = TestDataHelper.getStandardPricebookEntry(products[0].Id);
		PricebookEntry pbe1 = TestDataHelper.getStandardPricebookEntry(products[1].Id);
		PricebookEntry pbe2 = TestDataHelper.getStandardPricebookEntry(products[2].Id);

		Integer counter = 0;
		List<Order> orders = new List<Order>();
		while (counter < count) {
			orders.add(TestDataHelper.createOrder(location.Id, DateUtil.getNextWeekday(System.today())));
			counter++;
		}
		INSERT orders;

		List<OrderItem> orderItems = new List<OrderItem>();
		for (Order order : orders) {
			orderItems.add(TestDataHelper.createOrderItem(order.Id, products[0].Id, pbe0.Id));
			orderItems.add(TestDataHelper.createOrderItem(order.Id, products[1].Id, pbe1.Id));
			orderItems.add(TestDataHelper.createOrderItem(order.Id, products[2].Id, pbe2.Id));
			order.ShippingLatitude = shippingLatitude;
			order.ShippingLongitude = shippingLongitude;
			order.Status = 'Confirmed';
		}
		INSERT orderItems;
		UPDATE orders;
	}

	static void createCollectionOrder() {
		Account location = TestDataHelper.getLocation();
		Product2 product = TestDataHelper.getProducts(true)[0];
		PricebookEntry pbe = TestDataHelper.getStandardPricebookEntry(product.Id);

		Order order = TestDataHelper.insertOrder(location.Id, System.today());
		TestDataHelper.insertOrderItem(order.Id, product.Id, pbe.Id);
		order.Status = 'Confirmed';
		UPDATE order;
	}
}