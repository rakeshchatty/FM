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

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Product2 product = TestDataHelper.createProduct('Test Name', 'Test Code', 'Delivery');
		product.IsDeliveryByExternalCarrier__c = true;
		INSERT product;
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
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

	static void createOrders(Decimal shippingLatitude, Decimal shippingLongitude, Integer count) {
		Account location = TestDataHelper.getLocation();
		Product2 product = TestDataHelper.getProduct('Test Name');
		PricebookEntry pbe = TestDataHelper.gettPricebookEntry(product.Id, TestDataHelper.standardPricebook.Id);

		Integer counter = 0;
		List<Order> orders = new List<Order>();
		while (counter < count) {
			orders.add(TestDataHelper.createOrder(location.Id, Date.today()));
			counter++;
		}
		INSERT orders;

		List<OrderItem> orderItems = new List<OrderItem>();
		for (Order order : orders) {
			orderItems.add(TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id));
			order.ShippingLatitude = shippingLatitude;
			order.ShippingLongitude = shippingLongitude;
			order.Status = 'Confirmed';
		}
		INSERT orderItems;
		UPDATE orders;
	}
}