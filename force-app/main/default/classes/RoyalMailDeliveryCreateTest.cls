@isTest
private class RoyalMailDeliveryCreateTest {

	private static final Decimal LONDON_LAT = 51.74;
	private static final Decimal LONDON_LON = 00.32;
	private static final Decimal INNER_LONDON_LAT = 51.51;
	private static final Decimal INNER_LONDON_LON = -0.09;
	private static final Decimal NON_LONDON_LAT = 51.48;
	private static final Decimal NON_LONDON_LON = -1.88;

	@testSetup
	static void setup() {
		TestDataHelper.insertRoyalMailSetting();

		TestDataHelper.insertSupplierFirstMile();
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

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		List<DeliveryPackage__c> packages = [SELECT Id FROM DeliveryPackage__c];
		Assert.areEqual(2, packages.size());

		Attachment attachment = [SELECT Id FROM Attachment WHERE ParentId = :packages[0].Id AND Name LIKE 'RoyalMail Label - %.pdf'];
		Assert.isNotNull(attachment);
	}

	@isTest
	static void createPackageError() {
		createOrders(LONDON_LAT, LONDON_LON, 1);
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = Date.today() - 1, Carrier__c = DeliveryPackage.CARRIER_ROYAL_MAIL);

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		INSERT pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, TrackingIds__c, Message__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_ERROR, pkg.Status__c);
		Assert.isNull(pkg.TrackingIds__c);
		Assert.isNotNull(pkg.Message__c);

		try {
			Attachment attachment = [SELECT Id FROM Attachment WHERE ParentId = :pkg.Id AND Name LIKE 'RoyalMail Label - %.pdf'];
			Assert.fail();
		} catch (QueryException e) {}
	}

	@isTest
	static void createPackageBeyondMax() {
		createOrders(LONDON_LAT, LONDON_LON, TestDataHelper.MAX_ORDERS_PER_DAY_LONDON + 1);

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(TestDataHelper.MAX_ORDERS_PER_DAY_LONDON, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void createPackageBeyondMin() {
		createOrders(LONDON_LAT, LONDON_LON, 2);
		createOrders(INNER_LONDON_LAT, INNER_LONDON_LON, TestDataHelper.MIN_ORDERS_PER_DAY_LONDON + 1);

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(3, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void createPackageNonLondon() {
		createOrders(NON_LONDON_LAT, NON_LONDON_LON, TestDataHelper.MAX_ORDERS_PER_DAY_NON_LONDON + 1);

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(TestDataHelper.MAX_ORDERS_PER_DAY_NON_LONDON, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void retainBikeOrders() {
		createOrders(INNER_LONDON_LAT, INNER_LONDON_LON, TestDataHelper.MIN_ORDERS_PER_DAY_LONDON + 1);

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(1, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void countPackageBoxes() {
		createOrders(LONDON_LAT, LONDON_LON, 1);

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(26, [SELECT Count__c FROM DeliveryPackage__c].Count__c);
	}

	@isTest
	static void createCollectionPackage() {
		createCollectionOrder();

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		new DeliveryPackageCreationSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM DeliveryPackage__c].size());
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

	private class Mock implements HttpCalloutMock {

		Boolean isError = false;

		private Mock() {}

		private Mock(Boolean isError) {
			this.isError = isError;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse response = new HTTPResponse();
			RoyalMailDelivery.CreateResponse shipmentResponse = new RoyalMailDelivery.CreateResponse();

			if (isError) {
				shipmentResponse.Errors = new List<RoyalMailDelivery.Error>{new RoyalMailDelivery.Error()};
				shipmentResponse.Errors[0].Message = 'Random error message';
				response.setStatusCode(400);
			} else {
				shipmentResponse.Labels = 'Random mock data for labels';
				shipmentResponse.Packages = new List<RoyalMailDelivery.ResponsePackage>{new RoyalMailDelivery.ResponsePackage()};
				shipmentResponse.Packages[0].TrackingNumber = String.valueOf(Integer.valueof((Math.random() * 1234567890)));
				response.setStatusCode(200);
			}

			response.setBody(JSON.serialize(shipmentResponse));
			return response;
		}
	}
}