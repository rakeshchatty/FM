@isTest
public class TestDataHelper {

	public static final Integer MIN_ORDERS_PER_DAY_LONDON = 3;
	public static final Integer MAX_ORDERS_PER_DAY_LONDON = 5;
	public static final Integer MAX_ORDERS_PER_DAY_NON_LONDON = 5;
	public static final Integer MAX_BAGS_PER_PARCEL = 2;
	public static final Integer MAX_ORDER_AMOUNT = 4000;

	private static Id recordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
	private static Id recordTypeIdPartner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
	private static Id recordTypeIdLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
	private static Id recordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
	private static Id recordTypeIdSupplier = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Supplier').getRecordTypeId();

	private static Pricebook2 standardPricebook;	// DO NOT initialize within static block, as callouts may fail due to UPDATE pending to commit
	private static Id getStandardPricebookId() {
		if (standardPricebook == null) {
			if (Test.isRunningTest()) {
				standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
				UPDATE standardPricebook;
			} else {
				standardPricebook = [SELECT Id FROM Pricebook2 WHERE IsStandard = true AND IsActive = true];
			}
		}
		return standardPricebook.Id;
	}

	public static Account createAccount() {
		return new Account(Name = 'Parent', RecordTypeId = recordTypeIdAccount, Price_Book__c = getStandardPricebookId(), Enqix_Dead_Live__c = 'Live');
	}

	public static Account createPartner() {
		return new Account(Name = 'Partner', RecordTypeId = recordTypeIdPartner, Price_Book__c = getStandardPricebookId(), Enqix_Dead_Live__c = 'Live', Parter_type__c = 'BID');
	}

	public static Account createLocation(Id parentId, Id partnershipId) {
		return createLocation(parentId, partnershipId, null);
	}

	public static Account createLocation(Id parentId, Id partnershipId, String mobaAccountCode) {
		return new Account(Name = 'Location', ParentId = parentId, Partnership__c = partnershipId, RecordTypeId = recordTypeIdLocation, Price_Book__c = getStandardPricebookId(), Enqix_Dead_Live__c = 'Live', MOBA_Account_Code__c = mobaAccountCode);
	}

	public static Account createProspect(Id parentId, Id partnershipId) {
		return new Account(Name = 'Prospect', ParentId = parentId, Partnership__c = partnershipId, RecordTypeId = recordTypeIdProspect);
	}

	public static Account insertAccount() {
		LegalEntity__c legalEntity = insertLegalEntity('First Mile');
		Account parent = createAccount();
		parent.OwningEntity__c = legalEntity.Id;
		INSERT parent;
		return parent;
	}

	public static Account insertPartner() {
		Account partner = createPartner();
		INSERT partner;
		return partner;
	}

	public static Account insertLocation(Id parentId, Id partnershipId) {
		Account location = createLocation(parentId, partnershipId);
		INSERT location;
		return location;
	}

	public static Account insertLocation(Id parentId, Id partnershipId, String mobaAccountCode) {
		Account location = createLocation(parentId, partnershipId, mobaAccountCode);
		INSERT location;
		return location;
	}

	public static Account getLocation() {
		return [SELECT Id FROM Account WHERE RecordTypeId = :recordTypeIdLocation LIMIT 1];
	}

	public static Account insertProspect(Id parentId, Id partnershipId) {
		Account prospect = createProspect(parentId, partnershipId);
		INSERT prospect;
		return prospect;
	}

	public static Account insertSupplierAccount(String name) {
		Account supplierAccount = new Account(Name = name, RecordTypeId = recordTypeIdSupplier, SupplierEmail__c = 'test@gmail.com', SupplierEscalationEmail__c = 'test1@gmail.com');
		INSERT supplierAccount;
		return supplierAccount;
	}

	public static Contact insertContact(Id AccountId, String lastName) {
		Contact contact = new Contact(AccountId = AccountId, FirstName = 'test', LastName = lastName, Email = 'test'+lastName+'@fm.com', MobilePhone = '07123456789');
		INSERT contact;
		return contact;
	}

	public static Contact insertContact(Id AccountId, String lastName, Decimal hubSpotId) {
		Contact contact = new Contact(AccountId = AccountId, FirstName = 'test', LastName = lastName, Email = 'test'+lastName+'@fm.com', MobilePhone = '07123456789', HubSpotId__c = hubSpotId);
		INSERT contact;
		return contact;
	}

	public static AccountContactRelation insertAccountContactRelation(Id AccountId, Id ContactId, string Role) {
		AccountContactRelation acr = new AccountContactRelation(AccountId = AccountId, ContactId = ContactId, Roles = Role);
		INSERT acr;
		return acr;
	}

	public static Product_Category__c insertProductCategory(String name) {
		Product_Category__c productCategory = new Product_Category__c(Name = name);
		INSERT productCategory;
		return productCategory;
	}

	public static Waste_Category__c insertWasteCategory(String name, String code) {
		Waste_Category__c  wasteCategory = new Waste_Category__c(Name = name, Codes__c = code);
		INSERT wasteCategory;
		return wasteCategory;
	}

	public static Product2 insertProduct(String name, String code, String type) {
		return insertProduct(name, code, type, null);
	}

	public static Product2 insertProduct(String name, String code, String type, Id productCategoryId) {
		Product2 product = createProduct(name, code, type, productCategoryId);
		INSERT product;
		return product;
	}

	public static Product2 insertProduct(String name, String code, String type, Id containerTypeId, Id binRentalProductId) {
		Product2 product = createProduct(name, code, type, null, null, containerTypeId, null);
		product.BinRentalProduct__c = binRentalProductId;
		INSERT product;
		return product;
	}

	public static Product2 createProduct(String name, String code, String type) {
		return createProduct(name, code, type, null);
	}

	public static Product2 createProduct(String name, String code, String type, Id productCategoryId) {
		return createProduct(name, code, type, productCategoryId, null, null, null);
	}

	public static Product2 createProduct(String name, String code, String type, Id productCategoryId, Id wasteCategoryId, Id containerTypeId, String enqixId) {
		return new Product2(IsActive = true, Nl_accode__c = '4001', Name = name, ProductCode = code, Product_Type__c = type, Product_Category__c = productCategoryId, Waste_Category__c = wasteCategoryId, Container_Type__c = containerTypeId, Enqix_Id__c = enqixId);
	}

	public static Product2 getProduct(String name) {
		return [SELECT Id FROM Product2 WHERE Name = :name LIMIT 1];
	}

	public static List<Product2> getProducts() {
		return getProducts(false);
	}

	public static List<Product2> getProducts(Boolean isCollection) {
		return [SELECT Id FROM Product2 WHERE IsCollection__c = :isCollection];
	}

	public static PricebookEntry insertPricebookEntry(Id pricebookId, Id productId, Decimal price) {
		PricebookEntry pbe = createPricebookEntry(pricebookId, productId, price);
		INSERT pbe;
		return pbe;
	}

	public static PricebookEntry insertStandardPricebookEntry(Id productId, Decimal price) {
		return insertPricebookEntry(getStandardPricebookId(), productId, price);
	}

	public static PricebookEntry createPricebookEntry(Id pricebookId, Id productId, Decimal price) {
		return new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productId, UnitPrice = price, IsActive = true);
	}

	public static PricebookEntry createStandardPricebookEntry(Id productId, Decimal price) {
		return createPricebookEntry(getStandardPricebookId(), productId, price);
	}

	public static PricebookEntry getPricebookEntry(Id productId, Id pricebookId) {
		return [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id = :productId];
	}

	public static PricebookEntry getStandardPricebookEntry(Id productId) {
		return getPricebookEntry(productId, getStandardPricebookId());
	}

	public static Order insertOrder(Id locationId) {
		Order order = createOrder(locationId, null);
		order.Delivery_Date__c = System.today();

		INSERT order;
		return order;
	}

	public static Order insertOrder(Id locationId, Date requestedDeliveryDate) {
		Order order = createOrder(locationId, requestedDeliveryDate);
		INSERT order;
		return order;
	}

	public static Order createOrder(Id locationId, Date requestedDeliveryDate) {
		return new Order(AccountId = locationId, Status = 'Draft', EffectiveDate = System.today(), Requested_Delivery_Date__c = requestedDeliveryDate);
	}

	public static OrderItem insertOrderItem(Id orderId, Id productId, Id priceBookEntryId) {
		OrderItem orderItem = createOrderItem(orderId, productId, priceBookEntryId);
		INSERT orderItem;
		return orderItem;
	}

	public static OrderItem createOrderItem(Id orderId, Id productId, Id priceBookEntryId) {
		return new OrderItem(OrderId = OrderId, Product2Id = ProductId, PriceBookEntryId = PriceBookEntryId, Quantity = 3, UnitPrice = 100);
	}

	public static Invoice_Header__c insertInvoice(Id accountId, Id orderId, String frequency) {
		Invoice_Header__c invoice = new Invoice_Header__c(Account__c = accountId, OrderLookUp__c = orderId, InvoiceFrequency__c = frequency);
		INSERT invoice;
		return invoice;
	}

	public static Invoice_Line__c insertInvoiceLine(Id invoiceId) {
		Invoice_Line__c invoiceLine = new Invoice_Line__c(Name = 'Line 1', Invoice_HeaderId__c = invoiceId);
		INSERT invoiceLine;
		return invoiceLine;
	}

	public static TheVat__c insertVat() {
		TheVat__c vat = new TheVat__c(Value__c = 20);
		INSERT vat;
		return vat;
	}

	public static void insertSendGridSetting() {
		INSERT new SendGridSetting__c(FromEmail__c = 'UnitTestCode@email.com', FromName__c = 'Unit Test Code',
			IsInvoiceEmailEnabled__c = true, IsFlowEmailEnabled__c = true, IsEmailEnabled__c = true);
	}

	public static DeliveryPackage__c createDeliveryPackage(Id orderId, String status, Date requestedDeliveryDate, String carrier) {
		return new DeliveryPackage__c(Order__c = orderId, Status__c = status, RequestedDeliveryDate__c = requestedDeliveryDate, Carrier__c = carrier);
	}

	public static DeliveryPackage__c createDeliveryPackage(Id orderId, String status, Date requestedDeliveryDate) {
		return createDeliveryPackage(orderId, status, requestedDeliveryDate, DeliveryPackage.CARRIER_PARCELFORCE);
	}

	public static DeliveryPackage__c createDeliveryPackage(Id orderId) {
		return createDeliveryPackage(orderId, DeliveryPackage.STATUS_NEW, Date.today());
	}

	public static DeliveryPackage__c insertDeliveryPackage(Id orderId, String status) {
		return insertDeliveryPackage(orderId, status, DeliveryPackage.CARRIER_PARCELFORCE);
	}

	public static DeliveryPackage__c insertDeliveryPackage(Id orderId, String status, String carrier) {
		DeliveryPackage__c pkg = createDeliveryPackage(orderId, status, Date.today(), carrier);
		INSERT pkg;
		return pkg;
	}

	public static DeliveryPackageQrCode__c createDeliveryPackageQrCode(Id pkgId, Id orderItemId, String code) {
		return new DeliveryPackageQrCode__c(DeliveryPackage__c = pkgId, OrderProduct__c = orderItemId, Code__c = code);
	}

	public static DeliveryPackageQrCode__c insertDeliveryPackageQrCode(Id pkgId, Id orderItemId, String code) {
		DeliveryPackageQrCode__c qrCode = createDeliveryPackageQrCode(pkgId, orderItemId, code);
		INSERT qrCode;
		return qrCode;
	}

	public static void insertParcelforceSetting() {
		INSERT new ParcelforceSetting__c(WireNumber__c = 'TA0I', ContractNumber__c = 'K448478', ServiceCode__c = 'SND',
			StatusCancelled__c ='I108',
			StatusRedelivery__c = 'I112,I135,I159,I160,I161,I162',
			StatusDelivered__c = 'I102,I136,I138,I139,I181,I182,I184,I210,I211,I212,I213,I214,I215,I232,I233,IBPD,ICCP,IPDF,IPDP,IPMD',
			BagsPerParcel__c = MAX_BAGS_PER_PARCEL,
			MaximumOrderAmount__c = MAX_ORDER_AMOUNT,
			MinimumOrdersPerDayLondon__c = MIN_ORDERS_PER_DAY_LONDON, MaximumOrdersPerDayLondon__c = MAX_ORDERS_PER_DAY_LONDON, MaximumOrdersPerDayNonLondon__c = MAX_ORDERS_PER_DAY_NON_LONDON);
	}

	public static void insertRoyalMailSetting() {
		INSERT new RoyalMailSetting__c(WireNumber__c = 'TA0I', ShippingAccountId__c = 'K448478', ShippingLocationId__c = 'K44ABCD', ServiceCode__c = 'SND',
			IsActive__c = true, DeclaredWeight__c = 1.5, DescriptionOfGoods__c = 'Waste containers',
			StatusCancelled__c ='I108',
			StatusReturnedToSender__c = 'I112,I135,I159,I160,I161,I162',
			StatusDelivered__c = 'I102,I136,I138,I139,I181,I182,I184,I210,I211,I212,I213,I214,I215,I232,I233,IBPD,ICCP,IPDF,IPDP,IPMD',
			BagsPerParcel__c = MAX_BAGS_PER_PARCEL,
			MaximumOrderAmount__c = MAX_ORDER_AMOUNT,
			MinimumOrdersPerDayLondon__c = MIN_ORDERS_PER_DAY_LONDON, MaximumOrdersPerDayLondon__c = MAX_ORDERS_PER_DAY_LONDON, MaximumOrdersPerDayNonLondon__c = MAX_ORDERS_PER_DAY_NON_LONDON);
	}

	public static Round__c insertRound() {
		return insertRound(false);
	}

	public static Round__c insertRound(Boolean isSequencingEnabled) {
		Depot__c depot = insertDepot();
		Round__c round = createRound(depot, depot, isSequencingEnabled);
		INSERT round;
		return round;
	}

	public static Round__c createRound(Depot__c startDepot, Depot__c endDepot, Boolean isSequencingEnabled) {
		return createRound('Test Round 1', 1, startDepot, endDepot, isSequencingEnabled);
	}

	public static Round__c createRound(String name, Integer roundNo, String roundType) {
		Depot__c depot = insertDepot();
		Round__c round = createRound(name, roundNo, depot, depot, false);
		round.Round_Type__c = roundType;
		return round;
	}

	public static Round__c createRound(String name, Integer roundNo, Depot__c startDepot, Depot__c endDepot, Boolean isSequencingEnabled) {
		Round__c round = new Round__c(RoundNo__c = roundNo, Name = name, Type__c = 'Collection',
			StartDepot__c = startDepot?.Id, EndDepot__c = endDepot?.Id, IsSequencingEnabled__c = isSequencingEnabled, Round_Type__c = 'AM', StartTime__c = '07:00',
			Mon__c = true, Tue__c = true, Wed__c = true, Thu__c = true, Fri__c = true, Sat__c = true, Sun__c = true);
		return round;
	}

	public static Suppliers__c insertSupplierFirstMile() {
		return insertSupplier('First Mile Ltd');
	}

	public static Suppliers__c insertSupplier(String name) {
		Account supplierAccount = insertSupplierAccount(name);

		Suppliers__c supplier = new Suppliers__c(SupplierAccount__c = supplierAccount.Id, Name = name, Phone_Number__c = '01234567890', Email__c = 'email@email.com');
		INSERT supplier;
		return supplier;
	}

	public static Supplier_Product__c insertSupplierProduct(Suppliers__c supplier, Product2 product) {
		Supplier_Product__c supplierProduct = new Supplier_Product__c(Supplier__c = supplier.Id, Product__c = product.id, Name = 'Test');
		INSERT supplierProduct;
		return supplierProduct;
	}

	public static Schedule__c createSchedule(Account location, Round__c round, Suppliers__c supplier, Supplier_Product__c supplierProduct, String collectionTime) {
		return new Schedule__c(Location__c = location.Id, Round__c = round.Id, Supplier__c = supplier.Id, Supplier_Product__c = supplierProduct.Id,
			Days__c = 'Monday;Tuesday;Wednesday;Thursday;Friday;Saturday;Sunday', Time__c = collectionTime, Collection_Quantity__c = 2,
			Start_Date__c = System.today());
	}

	public static Schedule__c insertSchedule(Account location, Round__c round, Suppliers__c supplier, Supplier_Product__c supplierProduct, String collectionTime) {
		Schedule__c schedule = createSchedule(location, round, supplier, supplierProduct, collectionTime);
		INSERT schedule;
		return schedule;
	}

	public static Container_Type__c insertContainerType(String name) {
		Container_Type__c containerType = new Container_Type__c(Name = name, Type__c = name);
		INSERT containerType;
		return containerType;
	}

	public static Container_Type__c insertContainerType(String name, String type) {
		Container_Type__c containerType = new Container_Type__c(Name = name, Type__c = type);
		INSERT containerType;
		return containerType;
	}

	public static void insertCollectionServiceTimeSetting() {
		INSERT new CollectionServiceTimeSetting__c();
	}

	public static void insertOverweightSetting(Id gwProductCategoryId, Id dmrProductCategoryId, Id gwChargeProductId, Id dmrChargeProductId,
		Id fdProductCategoryId, Id glsProductCategoryId, Id fdChargeProductId, Id glsChargeProductId) {
			INSERT new OverweightSetting__c(GeneralWasteProductCategoryId__c = gwProductCategoryId, MixedRecyclingProductCategoryId__c = dmrProductCategoryId,
				GeneralWasteChargeProductId__c = gwChargeProductId, MixedRecyclingChargeProductId__c = dmrChargeProductId,
				FoodProductCategoryId__c = fdProductCategoryId, FoodChargeProductId__c = fdChargeProductId,
				GlassProductCategoryId__c = glsProductCategoryId, GlassChargeProductId__c = glsChargeProductId);
	}

	public static Depot__c insertDepot() {
		Depot__c depot = new Depot__c(Name = 'Depot 1', ContactName__c = 'Some name',
			Address__Street__s = 'Some street', Address__City__s = 'Some City', Address__PostalCode__s = 'Some Postcode', Address__CountryCode__s = 'GB',
			Coordinates__Latitude__s = 51.52925400, Coordinates__Longitude__s = -0.26425068);
		INSERT depot;
		return [SELECT Id, Index__c FROM Depot__c WHERE Id = :depot.Id];
	}

	public static void insertRoutingSetting() {
		INSERT new RoutingSetting__c(MaximumPollCount__c = 2, Licence__c = 'AbcXyz');
	}

	public static RoutingParameterOverride__mdt getRoutingOverrides(String developerName) {
		return new RoutingParameterOverride__mdt(StartDepotIndex__c = 1, EndDepotIndex__c = 1);
	}

	public static DailyDispatch__c insertDispatch(Round__c round) {
		return insertDispatch(round, null);
	}

	public static DailyDispatch__c insertDispatch(Round__c round, Integer jobId) {
		DailyDispatch__c dispatch = new DailyDispatch__c(RoundId__c = round.Id, Name = round.Name, RoutingJobId__c = jobId);
		INSERT dispatch;
		return dispatch;
	}

	public static DispatchLocation__c insertDispatchLocation(DailyDispatch__c dispatch, Account location) {
		DispatchLocation__c dispatchLocation = createDispatchLocation(dispatch, location);
		INSERT dispatchLocation;
		return dispatchLocation;
	}

	public static DispatchLocation__c createDispatchLocation(DailyDispatch__c dispatch, Account location) {
		return new DispatchLocation__c(Dispatch__c = dispatch.Id, Location__c = location.Id);
	}

	public static Collection_Waypoints__c insertWaypoint(Account location, DailyDispatch__c dispatch, DispatchLocation__c dispatchLocation) {
		Collection_Waypoints__c waypoint = createWaypoint(location, dispatch, dispatchLocation, null, null, null);
		INSERT waypoint;
		return waypoint;
	}

	public static Collection_Waypoints__c insertWaypoint(Account location, DailyDispatch__c dispatch, DispatchLocation__c dispatchLocation, Id scheduleId, Id supplierProductId, Decimal quantity) {
		Collection_Waypoints__c waypoint = createWaypoint(location, dispatch, dispatchLocation, scheduleId, supplierProductId, quantity);
		INSERT waypoint;
		return waypoint;
	}

	public static Collection_Waypoints__c createWaypoint(Account location, DailyDispatch__c dispatch, DispatchLocation__c dispatchLocation) {
		Collection_Waypoints__c waypoint = new Collection_Waypoints__c(Location__c = location.Id, Daily_Dispatch__c = dispatch.Id, DispatchLocation__c = dispatchLocation.Id);
		return waypoint;
	}

	public static Collection_Waypoints__c createWaypoint(Account location, DailyDispatch__c dispatch, DispatchLocation__c dispatchLocation, Id scheduleId, Id supplierProductId, Decimal quantity) {
		Collection_Waypoints__c waypoint = new Collection_Waypoints__c(Location__c = location.Id, Daily_Dispatch__c = dispatch.Id, DispatchLocation__c = dispatchLocation.Id, Collection_Schedule__c = scheduleId, Supplier_Product__c = supplierProductId, Collection_Quantity__c = quantity);
		return waypoint;
	}

	public static Recurrings__c insertRecurring(Id accountId, Id productId, Id supplierId) {
		Recurrings__c recurring  = new Recurrings__c(Account__c = accountId, Product__c = productId, Supplier__c = supplierId, Name = 'Test Recurring', Active__c = true, Type__c = 'Delivery', First_Date__c = Date.today().addDays(1), Rec__c = 'Month', Recur_Every__c = '1');
		INSERT recurring;
		return recurring;
	}

	public static Vehicle__c insertVehicle(String name) {
		Vehicle__c vehicle = new Vehicle__c(Name = name, Active__c = true);
		INSERT vehicle;
		return vehicle;
	}

	public static LegalEntity__c insertLegalEntity(String name) {
		LegalEntity__c entity = new LegalEntity__c(Name = name, Logo__c = 'some logo',
			RegistrationNumber__c = '12345', VatNumber__c = '09876', BankAccountNumber__c = '12345678', BankSortCode__c = '123456',
			TermsOfService__c = 'link to terms', Website__c = 'wwww.thefirstmile.co.uk',
			Phone__c = '03333003448', AccountsEmail__c = 'test1@test.com', Email__c = 'test2@test.com',
			InvoiceTemplate__c ='d-2fa0d0b2c86748088f8110991eee40de', CreditNoteTemplate__c ='d-0009c7448f80452da503547551218575',
			InvoiceSenderName__c = name, InvoiceSenderEmail__c = 'test1@test.com',
			Address__Street__s = 'Street line 1', Address__City__s = 'London', Address__PostalCode__s = 'AB1 9DE');
		INSERT entity;
		return entity;
	}

	public static void setDefaultLegalEntity(Id id) {
		INSERT new EntitySetting__c(DefaultLegalEntityId__c = id);
	}

	public static void insertDefaultLegalEntity(String name) {
		setDefaultLegalEntity(insertLegalEntity(name).Id);
	}

	public static void insertAdditionalChargeSetting(Id binChargeProductId, Id bagChargeProductId, String binContainerNames, String bagContainerNames) {
		INSERT new AdditionalChargeSetting__c(IsDeliveryChargeActive__c = true, BinDeliveryChargeProduct__c = binChargeProductId, BinContainerNames__c = binContainerNames,
			BagDeliveryChargeProduct__c = bagChargeProductId, BagContainerNames__c = bagContainerNames);
	}

	public static void insertFuelSurchargeSetting(Id productId, Decimal surcharge) {
		INSERT new FuelSurchargeSetting__c(IsActive__c = true, ProductId__c = productId, Surcharge__c = surcharge);
	}

	public static Facility__c insertFacility(String name) {
		Facility__c facility = new Facility__c(Name = name);
		INSERT facility;
		return facility;
	}

	public static WasteDestination__c insertWasteDestination(Id facilityId, Date startDate, Date endDate, String serviceType, String serviceSubtype) {
		WasteDestination__c wasteDestination = new WasteDestination__c(Facility__c = facilityId, StartDate__c = startDate, EndDate__c = endDate, ServiceType__c = serviceType, ServiceSubtype__c = serviceSubtype);
		INSERT wasteDestination;
		return wasteDestination;
	}

	public static void suppressSuspensionDateValidation() {
		INSERT new ByPassSetting__c(SetupOwnerId = UserInfo.getOrganizationId(), SuspensionDateValidation__c = true);
	}

	public static ScheduleSuspension__c createScheduleSuspension(Id aggregatorId, Date suspensionDate, Date reactivationDate) {
		return new ScheduleSuspension__c(Aggregator__c = aggregatorId, SuspensionDate__c = suspensionDate, ReactivationDate__c = reactivationDate, IsActive__c = true);
	}
}