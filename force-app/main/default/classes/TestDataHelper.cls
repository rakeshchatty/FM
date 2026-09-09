@isTest
public class TestDataHelper {

	public static final Integer MIN_ORDERS_PER_DAY_LONDON = 3;
	public static final Integer MAX_ORDERS_PER_DAY_LONDON = 5;
    public static final Integer MAX_ORDERS_PER_DAY_NON_LONDON = 5;
	public static final Integer MAX_BAGS_PER_PARCEL = 2;

	private static Id recordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
	private static Id recordTypeIdPartner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
	private static Id recordTypeIdLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
	private static Id recordTypeIdProspect = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();

	public static Pricebook2 standardPricebook;
	static {
		standardPricebook = new Pricebook2(Id = Test.getStandardPricebookId(), IsActive = true);
		UPDATE standardPricebook;
	}

	public static Account createAccount() {
		return new Account(Name = 'Parent', RecordTypeId = recordTypeIdAccount, Price_Book__c = standardPricebook.Id, Enqix_Dead_Live__c = 'Live');
	}

	public static Account createPartner() {
		return new Account(Name = 'Partner', RecordTypeId = recordTypeIdPartner, Price_Book__c = standardPricebook.Id, Enqix_Dead_Live__c = 'Live');
	}

	public static Account createLocation(Id parentId, Id partnershipId) {
		return new Account(Name = 'Location', ParentId = parentId, Partnership__c = partnershipId, RecordTypeId = recordTypeIdLocation, Price_Book__c = standardPricebook.Id, Enqix_Dead_Live__c = 'Live');
	}

	public static Account createProspect(Id parentId, Id partnershipId) {
		return new Account(Name = 'Prospect', ParentId = parentId, Partnership__c = partnershipId, RecordTypeId = recordTypeIdProspect);
	}

	public static Account insertAccount() {
		Account parent = createAccount();
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

	public static Account getLocation() {
		return [SELECT Id FROM Account WHERE RecordTypeId = :recordTypeIdLocation LIMIT 1];
	}

	public static Account insertProspect(Id parentId, Id partnershipId) {
		Account prospect = createProspect(parentId, partnershipId);
		INSERT prospect;
		return prospect;
	}

	public static Contact insertContact(Id AccountId, String lastName) {
		Contact contact = new Contact(AccountId = AccountId, FirstName = 'test', LastName = lastName, Email = 'test'+lastName+'@fm.com');
		INSERT contact;
		return contact;
	}

	public static AccountContactRelation insertAccountContactRelation(Id AccountId, Id ContactId, string Role) {
		AccountContactRelation acr = new AccountContactRelation(AccountId = AccountId, ContactId = ContactId, Roles = Role);
		INSERT acr;
		return acr;
	}

	public static Product2 insertProduct(String name, String code, String type) {
		return insertProduct(name, code, type, null);
	}

	public static Product2 createProduct(String name, String code, String type) {
		return createProduct(name, code, type, null);
	}

	public static Product2 insertProduct(String name, String code, String type, Id productCategoryId) {
		Product2 product = createProduct(name, code, type, productCategoryId);
		INSERT product;
		return product;
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

	public static PricebookEntry insertPricebookEntry(Id pricebookId, Id productId, Decimal price) {
		PricebookEntry pbe = new PricebookEntry(Pricebook2Id = pricebookId, Product2Id = productId, UnitPrice = price, IsActive = true);
		INSERT pbe;
		return pbe;
	}

	public static PricebookEntry insertStandardPricebookEntry(Id productId, Decimal price) {
		return insertPricebookEntry(standardPricebook.Id, productId, price);
	}

	public static PricebookEntry gettPricebookEntry(Id productId, Id pricebookId) {
		return [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :pricebookId AND Product2Id = :productId];
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
		TheVat__c vat = new TheVat__c(Value__c = 0.2);
		INSERT vat;
		return vat;
	}

	public static void insertSendGridSetting() {
		INSERT new SendGridSetting__c(FromEmail__c = 'UnitTestCode@email.com', FromName__c = 'Unit Test Code',
			InvoiceTemplate__c ='d-2fa0d0b2c86748088f8110991eee40de', CreditNoteTemplate__c ='d-0009c7448f80452da503547551218575',
			IsInvoiceEmailEnabled__c = true, IsFlowEmailEnabled__c = true, IsEmailEnabled__c = true);
	}

	public static DeliveryPackage__c createDeliveryPackage(Id orderId) {
		return new DeliveryPackage__c(Order__c = orderId, RequestedDeliveryDate__c = Date.Today());
	}

	public static DeliveryPackage__c insertDeliveryPackage(Id orderId, String status) {
		DeliveryPackage__c pkg = createDeliveryPackage(orderId);
		pkg.Status__c = status;

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
		INSERT new ParcelforceSetting__c(WireNumber__c = 'TA0I', ContractNumber__c = 'K448478', ServiceCode__c = 'SND', ShipmentType__c ='DELIVERY',
			StatusCancelled__c ='I108',
			StatusRedelivery__c = 'I112,I135,I159,I160,I161,I162',
			StatusDelivered__c = 'I102,I136,I138,I139,I181,I182,I184,I210,I211,I212,I213,I214,I215,I232,I233,IBPD,ICCP,IPDF,IPDP,IPMD',
			BagsPerParcel__c = MAX_BAGS_PER_PARCEL,
			MinimumOrdersPerDayLondon__c = MIN_ORDERS_PER_DAY_LONDON, MaximumOrdersPerDayLondon__c = MAX_ORDERS_PER_DAY_LONDON, MaximumOrdersPerDayNonLondon__c = MAX_ORDERS_PER_DAY_NON_LONDON);
	}

	public static Round__c insertRound() {
		Round__c round = new Round__c(RoundNo__c = 1, Name = 'Test Round 1',
			Mon__c = true, Tue__c = true, Wed__c = true, Thu__c = true, Fri__c = true, Sat__c = true, Sun__c = true);
		INSERT round;
		return round;
	}

	public static Suppliers__c insertSupplier(String name) {
		Suppliers__c supplier = new Suppliers__c(Name = name, Phone_Number__c = '01234567890');
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
		Container_Type__c containerType = new Container_Type__c(Name = name);
		INSERT containerType;
		return containerType;
	}

	public static void insertCollectionServiceTimeSetting() {
		INSERT new CollectionServiceTimeSetting__c();
	}
}