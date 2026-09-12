public with sharing class OrderController {

	public class OrderData {
		@AuraEnabled public Id locationId { get; set; }
		@AuraEnabled public String type { get; set; }
		@AuraEnabled public Id contactId { get; set; }
		@AuraEnabled public String poNumber { get; set; }
		@AuraEnabled public String requestedDeliveryDate { get; set; }
		@AuraEnabled public String deliveryNotes { get; set; }
		@AuraEnabled public Boolean isPaymentConfirmed { get; set; }
		@AuraEnabled public Id priceBookId { get; set; }
		@AuraEnabled public Decimal totalPrice { get; set; }
		@AuraEnabled public Decimal vat { get; set; }
		@AuraEnabled public Decimal totalPriceIncludingVat { get { return totalPrice + vat; } }
		@AuraEnabled public List<OrderItemData> orderItems { get; set; }
	}

	public class OrderItemData {
		@AuraEnabled public String rowKey { get; set; }
		@AuraEnabled public Id productId { get; set; }
		@AuraEnabled public Id pricebookEntryId { get; set; }
		@AuraEnabled public String manualProductName { get; set; }
		@AuraEnabled public Id supplierId { get; set; }
		@AuraEnabled public String supplierName { get; set; }
		@AuraEnabled public Decimal quantity { get; set; }
		@AuraEnabled public Decimal quantitySoldIn { get; set; }
		@AuraEnabled public Decimal listPrice { get; set; }
		@AuraEnabled public Decimal supplierUnitPrice { get; set; }
		@AuraEnabled public String discountToApply { get; set; }
		@AuraEnabled public Decimal parentDiscount { get; set; }
		@AuraEnabled public Decimal partnerDiscount { get; set; }
		@AuraEnabled public Id parentDiscountId { get; set; }
		@AuraEnabled public Id partnerDiscountId { get; set; }
		@AuraEnabled public Decimal discount { get { return discountToApply == null ? 0 : discountToApply == 'Account' ? parentDiscount : partnerDiscount; } }
		@AuraEnabled public Decimal unitPrice { get { return listPrice - discount; } }
		@AuraEnabled public Decimal totalPrice { get { return unitPrice * quantity; } }
		@AuraEnabled public Decimal vatRate { get; set; }
		@AuraEnabled public Id subscribedProductId { get; set; }
		@AuraEnabled public Decimal quantityRemaining { get; set; }
		@AuraEnabled public Decimal locationLimitQuantity { get; set; }
	}

	public virtual class ProductData {
		public ProductData() {}
		@AuraEnabled public PricebookEntry pricebookEntry { get; set; }
		@AuraEnabled public Suppliers__c supplier { get; set; }
		@AuraEnabled public Decimal quantitySoldIn { get; set; }
		@AuraEnabled public Subscribed_Products__c subscribedProduct { get; set; }

		public ProductData(PricebookEntry pricebookEntry, Suppliers__c supplier, Decimal quantitySoldIn, Subscribed_Products__c subscribedProduct) {
			this.pricebookEntry = pricebookEntry;
			this.supplier = supplier;
			this.quantitySoldIn = quantitySoldIn;
			this.subscribedProduct = subscribedProduct;
		}

		public ProductData(PricebookEntry pricebookEntry, Suppliers__c supplier, Decimal quantitySoldIn) {
			this(pricebookEntry, supplier, quantitySoldIn, null);
		}

		@AuraEnabled public Id pricebookEntryId { get { return pricebookEntry.Id; } }
		@AuraEnabled public Id productId { get { return pricebookEntry.Product2Id; } }
		@AuraEnabled public String productName { get { return pricebookEntry.Product2.Name; } }
		@AuraEnabled public Decimal listPrice { get { return pricebookEntry.UnitPrice; } }
		@AuraEnabled public Boolean isVatExempt { get { return pricebookEntry.Product2.IsVATExempt__c; } }
		@AuraEnabled public String productCategory { get { return pricebookEntry.Product2.Product_Category__r.Name; } }
		@AuraEnabled public String currencyCode { get { return pricebookEntry.CurrencyIsoCode; } }
		@AuraEnabled public Id supplierId { get { return supplier.Id; } }
		@AuraEnabled public String supplierName { get { return supplier.Name; } }
		@AuraEnabled public Id subscribedProductId { get { return (subscribedProduct != null) ? subscribedProduct.Id : null; } }
		@AuraEnabled public Decimal quantityRemaining { get { return (subscribedProduct != null) ? subscribedProduct.Quantity_Remaining2__c : null; } }
		@AuraEnabled public Decimal locationLimitQuantity { get { return (subscribedProduct != null) ? subscribedProduct.Enqix_BID_Location_Limit_Quantity__c : null; } }
	}

	public class Location {
		public Location() {}

		@AuraEnabled public Account location { get; set; }
		public Location(Account location) {
			this.location = location;
		}

		@AuraEnabled public String deliveryDays { get; set; }

		@AuraEnabled public Id id { get { return location.Id; } }
		@AuraEnabled public Id parentId { get { return location.ParentId; } }
		@AuraEnabled public Id partnershipId { get { return location.Partnership__c; } }
		@AuraEnabled public Id priceBookId { get { return location.Price_Book__c; } }
		@AuraEnabled public String name { get { return location.Name; } }
		@AuraEnabled public Boolean isPORequired { get { return location.Parent.PO_Required__c; } }
		@AuraEnabled public Boolean hasPartnership { get { return location.Partnership__c != null; } }
		@AuraEnabled public Boolean isVatExempt { get { return location.IsVATExemptLocation__c; } }
		@AuraEnabled public Boolean isNational { get { return location.IsNational__c; } }
		@AuraEnabled public Decimal parentAccountDiscount { get { return location.Parent.Account_Discount__c; } }
		@AuraEnabled public Decimal parentDirectDebitDiscount { get { return location.Parent.Direct_Debit_Discount__c; } }
		@AuraEnabled public String parentPaymentMethod { get { return location.Parent.Enqix_Payment_Method__c; } }
		@AuraEnabled public Boolean isDead { get { return (location.Enqix_Dead_Live__c == 'Dead' || location.Parent.Enqix_Dead_Live__c == 'Dead'); } }
		@AuraEnabled public Boolean isPriceBookActive { get { return location.Price_Book__r?.isActive; } }
		@AuraEnabled public Boolean isServiceSuspended { get { return (location.Parent.Account_Service_Status__c == 'Suspended'); } }
		@AuraEnabled public String effectiveCurrencyCode { get { return location.EffectiveCurrencyCode__c; } }
	}

	public class PicklistOptions {
		@AuraEnabled public String label { get; set; }
		@AuraEnabled public String value { get; set; }

		public PicklistOptions(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}

	//Initialing the UI the required data
	public class InitializingData {
		@AuraEnabled public Location location { get; set; }
		@AuraEnabled public List<PicklistOptions> orderTypes { get; set; }
		@AuraEnabled public List<Contact> contacts { get; set; }
		@AuraEnabled public List<ProductData> mostOrderedProducts { get; set; }
		@AuraEnabled public List<ProductData> subscribedProducts { get; set; }
		@AuraEnabled public List<ProductData> availableProducts { get; set; }
		@AuraEnabled public Date requestedDeliveryDate { get; set; }
	}

	private final static Suppliers__c FIRST_MILE_SUPPLIER = [SELECT Name FROM Suppliers__c WHERE IsExternal__c = false LIMIT 1];

	@AuraEnabled
	public static InitializingData init(String locationId) {
		try {
			InitializingData wrapper = new InitializingData();
			wrapper.location = getLocation(locationId);
			wrapper.contacts = getContacts(locationId);
			Map<String, Supplier_Product__c> supplierProductMap = getSupplierProductMap(null);
			Map<Id, Subscribed_Products__c> subscribedProductMap = getSubscribedProductMap(locationId);
			wrapper.subscribedProducts = getSubscribedProducts(wrapper.location, subscribedProductMap, supplierProductMap);
			wrapper.mostOrderedProducts = getMostOrderedProducts(wrapper.location, subscribedProductMap, supplierProductMap);
			wrapper.availableProducts = getAvailableProducts(wrapper.location, null);
			wrapper.orderTypes = getOrderTypes();

			String weekday = System.now().addDays(1).format('EEEE');
			if (weekday == 'Saturday') {
				wrapper.requestedDeliveryDate = Date.today().addDays(3);
			} else if (weekday == 'Sunday') {
				wrapper.requestedDeliveryDate = Date.today().addDays(2);
			} else {
				wrapper.requestedDeliveryDate = Date.today().addDays(1);
			}

			return wrapper;
		} catch (Exception e) {
			throw new AuraHandledException('Error initializing: ' + e.getMessage());
		}
	}

	@TestVisible
	private static Location getLocation(String locationId) {
		Account location = [SELECT Id, Name, IsNational__c, Parent.Price_Book__c, Parent.Direct_Debit_Discount__c, Parent.PO_Required__c, Parent.Account_Discount__c,
		PO_Required__c, Price_Book__c, Price_Book__r.isActive, Enqix_Dead_Live__c, ParentId, Partnership__c, IsVATExemptLocation__c, Parent.Account_Service_Status__c,
		Parent.Enqix_Payment_Method__c, Parent.Enqix_Dead_Live__c, ShippingPostcodeDistrict__r.DeliveryDays__c, Partnership__r.Id, EffectiveCurrencyCode__c
		FROM Account WHERE Id = :locationId];

		Location wrapper = new Location(location);
		if (location.ShippingPostcodeDistrict__r != null && location.ShippingPostcodeDistrict__r.DeliveryDays__c != null) {
			wrapper.deliveryDays = location.ShippingPostcodeDistrict__r.DeliveryDays__c.replace(';', ', ');
		}

		return wrapper;
	}

	private static List<PicklistOptions> getOrderTypes() {
		Schema.DescribeFieldResult fieldResult = Order.Type.getDescribe();
		List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

		List<PicklistOptions> picklistOptions = new List<PicklistOptions>();
		for (Schema.PicklistEntry picklistEntry : picklistEntries) {
			PicklistOptions.add(new PicklistOptions(picklistEntry.getLabel(), picklistEntry.getValue()));
		}

		return picklistOptions;
	}

	private static List<Contact> getContacts(String locationId) {
		Account location = [SELECT Id, ParentId FROM Account WHERE Id = :locationId];

		return [SELECT Id, Name, Email FROM Contact WHERE Email != null AND Id IN (SELECT ContactId FROM AccountContactRelation
		WHERE AccountId IN (:location.Id, :location.ParentId)) ORDER BY Account.RecordType.Name DESC];
	}

	private static List<ProductData> getMostOrderedProducts(Location location, Map<Id, Subscribed_Products__c> subscribedProductMap, Map<String, Supplier_Product__c> supplierProductMap) {
		List<ProductData> wrappers = new List<ProductData>();

		List<AggregateResult> aggregateResults = [SELECT Product2Id FROM OrderItem WHERE Product2.IsActive = true AND Order.AccountId = :location.id
		AND Product2.Product_Type__c = 'Delivery' AND CreatedDate >= LAST_N_MONTHS:12 GROUP BY Product2Id ORDER BY SUM(Quantity) DESC LIMIT 10];

		Set<Id> productIds = new Set<Id>();
		for (AggregateResult aggregateResult : aggregateResults) {
			productIds.add((Id)aggregateResult.get('Product2Id'));
		}

		if (productIds.isEmpty()) return wrappers;

		Map<Id, Suppliers__c> productSupplierMap = getProductSupplierMap(productIds, location.id, subscribedProductMap);

		List<PricebookEntry> pricebookEntries = [SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Description, Product2.Quantity_Sold_In__c, UnitPrice, Product2.Product_Category__r.Name, Product2.IsVATExempt__c, CurrencyIsoCode
			FROM PricebookEntry WHERE IsActive = true AND Pricebook2Id = :location.priceBookId AND Product2Id IN :productIds AND CurrencyIsoCode = :location.effectiveCurrencyCode];

		Suppliers__c supplier;
		Subscribed_Products__c subscribedProduct;
		Supplier_Product__c supplierProduct;
		for (PricebookEntry pricebookEntry : pricebookEntries) {
			supplier = productSupplierMap.get(pricebookEntry.Product2Id);
			subscribedProduct = subscribedProductMap.containsKey(pricebookEntry.Product2Id) ? subscribedProductMap.get(pricebookEntry.Product2Id) : null;
			supplierProduct = supplierProductMap.get(pricebookEntry.Product2Id + '-' + supplier.Id);
			Decimal quantitySoldIn = supplierProduct != null ? Math.max(supplierProduct.QuantitySoldIn__c, 1) : 1;
			ProductData wrapper = new ProductData(pricebookEntry, supplier, quantitySoldIn, subscribedProduct);
			wrappers.add(wrapper);
		}

		return wrappers;
	}

	private static List<ProductData> getSubscribedProducts(Location location, Map<Id, Subscribed_Products__c> subscribedProductMap, Map<String, Supplier_Product__c> supplierProductMap) {
		Set<Id> productIds = new Set<Id>();
		for (Subscribed_Products__c subscribedProduct : subscribedProductMap.values()) {
			productIds.add(subscribedProduct.Product__c);
		}

		Map<Id, PricebookEntry> pricebookEntries = new Map<Id, PricebookEntry>();
		for (PricebookEntry pricebookEntry : [SELECT Id, Product2Id, Product2.Name, Product2.Product_Category__r.Name, UnitPrice, Product2.IsVATExempt__c, CurrencyIsoCode
			FROM PricebookEntry WHERE IsActive = true AND Pricebook2Id = :location.priceBookId AND Product2Id IN :productIds AND CurrencyIsoCode = :location.effectiveCurrencyCode]) {
			pricebookEntries.put(pricebookEntry.Product2Id, pricebookEntry);
		}

		List<ProductData> wrappers = new List<ProductData>();
		Supplier_Product__c supplierProduct;
		for (Subscribed_Products__c subscribedProduct : subscribedProductMap.values()) {
			if (pricebookEntries.containsKey(subscribedProduct.Product__c)) {
				supplierProduct = SupplierProductMap.get(subscribedProduct.Product__c + '-' + subscribedProduct.Supplier__c);
				Decimal quantitySoldIn = supplierProduct != null ? Math.max(supplierProduct.QuantitySoldIn__c, 1) : 1;
				ProductData wrapper = new ProductData(pricebookEntries.get(subscribedProduct.Product__c), subscribedProduct.Supplier__r, quantitySoldIn, subscribedProduct);
				wrappers.add(wrapper);
			}
		}

		return wrappers;
	}

	private static Map<Id, Subscribed_Products__c> getSubscribedProductMap(String locationId) {
		List<Subscribed_Products__c> subscribedProducts = [SELECT Id, Product__c, Product__r.Name, Product__r.Family,Product__r.Description,
		Product__r.Quantity_Sold_In__c, Supplier__c, Supplier__r.Name, Quantity_Remaining2__c, Enqix_BID_Location_Limit_Quantity__c, SupplierProduct__r.Supplier_Price__c
		FROM Subscribed_Products__c WHERE Account__c = :locationId AND (EndDate__c >= TODAY OR EndDate__c = NULL)
		AND (StartDate__c <= TODAY OR StartDate__c = NULL) AND Product__r.IsActive = true AND IsActiveSupplier__c = true];

		Map<Id, Subscribed_Products__c> subscribedProductMap = new Map<Id, Subscribed_Products__c>();

		for (Subscribed_Products__c subscribedProduct : subscribedProducts) {
            if (subscribedProduct.Supplier__c == null) {
                subscribedProduct.Supplier__c = FIRST_MILE_SUPPLIER.Id;
                subscribedProduct.Supplier__r = FIRST_MILE_SUPPLIER;
            }
			subscribedProductMap.put(subscribedProduct.Product__c, subscribedProduct);
		}

		return subscribedProductMap;
	}

	private static Map<String, Supplier_Product__c> getSupplierProductMap(String supplierId) {
		Map<String, Supplier_Product__c> productSupplierMap = new Map<String, Supplier_Product__c>();
		String query = 'SELECT Product__c, Supplier__c, QuantitySoldIn__c, Supplier_Price__c FROM Supplier_Product__c ' +
						'WHERE Product__r.IsActive = true AND Supplier__r.Supplier_Active__c = true ' +
						'AND (End_Date__c >= TODAY OR End_Date__c = null)';

		if (supplierId != null) {
			query += ' AND Supplier__c =: supplierId';
		}

		List<Supplier_Product__c> supplierProducts = Database.query(query);

		for (Supplier_Product__c supplierProduct : supplierProducts) {
			productSupplierMap.put(supplierProduct.Product__c + '-' + supplierProduct.Supplier__c, supplierProduct);
		}
		return productSupplierMap;
	}

	@AuraEnabled(cacheable=true)
	public static List<ProductData> getAvailableProducts(Location location, String searchKey) {
		try {
			String pricebookId = location.priceBookId;
            String effectiveCurrencyCode = location.effectiveCurrencyCode;

			String query = 'SELECT Id, Product2Id, Product2.Name, Product2.Family, Product2.Description, Product2.Quantity_Sold_In__c, UnitPrice, Product2.Product_Category__r.Name, Product2.IsVATExempt__c, CurrencyIsoCode ' +
				'FROM PricebookEntry WHERE IsActive = true AND Pricebook2Id = :pricebookId AND Product2.Product_Type__c = \'Delivery\' AND CurrencyIsoCode = :effectiveCurrencyCode';

			if (String.isNotBlank(searchKey) && searchKey.length() > 2) {
				String searchTerm = '%' + searchKey + '%';
				query += ' AND (Product2.Name LIKE :searchTerm OR Product2.Description LIKE :searchTerm) ';
			}

			query += ' ORDER BY Product2.Name LIMIT 31';

			List<PricebookEntry> pricebookEntries = Database.query(query);

			List<ProductData> wrappers = new List<ProductData>();
			for (PricebookEntry pricebookEntry : pricebookEntries) {
				ProductData wrapper = new ProductData(pricebookEntry, FIRST_MILE_SUPPLIER, 1);
				wrappers.add(wrapper);
			}

			return wrappers;

		} catch (Exception e) {
			throw new AuraHandledException('Error fetching available products: ' + e.getMessage());
		}
	}

	@AuraEnabled(cacheable=true)
	public static OrderItemData addProductsToCart(ProductData product, String source, String selectedSupplierId, Location location) {
		Map<String, Supplier_Product__c> supplierProductMap = getSupplierProductMap(null);

		OrderItemData orderItem = new OrderItemData();
		orderItem.rowKey = 'new-' + System.now() + Math.random();
		orderItem.pricebookEntryId = product.pricebookEntryId;
		orderItem.productId = product.productId;
		orderItem.manualProductName = product.productName;
		orderItem.listPrice = product.listPrice;
		orderItem.vatRate = (product.isVatExempt || location.isVatExempt) ? 0 : Vat.DEFAULT_VAT_RATE;

		Supplier_Product__c supplierProduct = SupplierProductMap.get(product.productId + '-' + product.supplierId);
		if (source != 'available') {
			if (supplierProduct != null) {
				orderItem.quantity = orderItem.quantitySoldIn = product.quantitySoldIn;
				orderItem.supplierId = product.supplierId;
				orderItem.supplierName = product.supplierName;
				orderItem.subscribedProductId = product.subscribedProductId;
				orderItem.quantityRemaining = product.quantityRemaining;
				orderItem.locationLimitQuantity = product.locationLimitQuantity;
				orderItem.supplierUnitPrice = supplierProduct.Supplier_Price__c;
			} else {
				throw new AuraHandledException('Supplier has no association with this Product. Please select a different Product or a different Supplier');
			}
		} else {
			Map<Id, Subscribed_Products__c> subscribedProductMap = getSubscribedProductMap(location.Id);

			selectedSupplierId = selectedSupplierId != null ? selectedSupplierId : FIRST_MILE_SUPPLIER.Id;
			Suppliers__c supplier;
			Subscribed_Products__c subscribedProduct;
			if (subscribedProductMap.containsKey(product.productId)) {
				subscribedProduct = subscribedProductMap.get(product.productId);
				supplier = new Suppliers__c(Id = subscribedProduct.Supplier__c, Name = subscribedProduct.Supplier__r.Name);
				orderItem.subscribedProductId = subscribedProduct.Id;
				orderItem.quantityRemaining = subscribedProduct.Quantity_Remaining2__c;
				orderItem.locationLimitQuantity = subscribedProduct.Enqix_BID_Location_Limit_Quantity__c;
			} else if (selectedSupplierId != null && selectedSupplierId != FIRST_MILE_SUPPLIER.Id) {
				supplier = [SELECT Id, Name FROM Suppliers__c WHERE Id = :selectedSupplierId];
			} else {
				supplier = FIRST_MILE_SUPPLIER;
			}

			if (supplierProduct != null) {
				orderItem.supplierId = supplier.Id;
				orderItem.supplierName = supplier.Name;
				orderItem.quantitySoldIn = Math.max(supplierProduct.QuantitySoldIn__c, 1);
				orderItem.quantity = orderItem.quantitySoldIn;
				orderItem.supplierUnitPrice = supplierProduct.Supplier_Price__c;
			} else {
				throw new AuraHandledException('Supplier has no association with this Product. Please select a different Product or a different Supplier');
			}
		}

		applyDiscount(location, orderItem);

		return orderItem;
	}

	private static void applyDiscount(Location location, OrderItemData orderItem) {
		List<Subscribed_Products__c> subscribedProducts = [SELECT Id, Product__c, Product__r.Name, Product__r.Family,Product__r.Description,
			Product__r.Quantity_Sold_In__c, Supplier__c, Supplier__r.Name, Quantity_Remaining2__c, Enqix_BID_Location_Limit_Quantity__c, Last_Discount_Given__c,
			Enqix_BID_Location_Limit_Period__c, EndDate__c
			FROM Subscribed_Products__c WHERE Account__c = :location.Id AND Product__c = :orderItem.productId AND IsActiveSupplier__c = true
			AND (EndDate__c >= TODAY OR EndDate__c = NULL) AND (StartDate__c <= TODAY OR StartDate__c = NULL)  LIMIT 1];

		Map<Id, Account_Discount__c> parentDiscountMap = new Map<Id, Account_Discount__c>();
		Map<Id, Account_Discount__c> partnerDiscountMap = new Map<Id, Account_Discount__c>();
		for (Account_Discount__c accountDiscount : [SELECT Id, Name, Product__c, Product__r.Name, Product_Discount__c, Gross_Price_f__c, BID_Price__c,Account__r.RecordTypeId, Account__r.RecordType.Name, Discount_Type__c FROM Account_Discount__c
		WHERE (Account__c = :location.parentId OR Account__c = :location.partnershipId) AND Product__c = :orderItem.productId
		AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)
		ORDER BY Account__r.RecordType.Name]) {
			if (accountDiscount.Account__c == location.partnershipId) {
				partnerDiscountMap.put(accountDiscount.Product__c, accountDiscount);
			}
			if (accountDiscount.Account__c == location.parentId) {
				parentDiscountMap.put(accountDiscount.Product__c, accountDiscount);
			}
		}

		Decimal overridingDiscount = location.parentAccountDiscount;
		Boolean hasOverridingDiscount = overridingDiscount != null && overridingDiscount > 0;
		Decimal directDebitDiscount = location.parentDirectDebitDiscount;
		Boolean hasDirectDebitDiscount = directDebitDiscount != null && directDebitDiscount > 0;

		Account_Discount__c accountDiscount;
		orderItem.parentDiscount = orderItem.partnerDiscount = 0;

		if (parentDiscountMap.containsKey(orderItem.productId)) {
			accountDiscount = parentDiscountMap.get(orderItem.productId);
			Decimal discount = accountDiscount.Product_Discount__c == null ? 0 : accountDiscount.Product_Discount__c;
			Decimal priceWithDiscount = orderItem.listPrice - discount;

			orderItem.parentDiscount = discount + (hasOverridingDiscount ? (priceWithDiscount * (overridingDiscount / 100)) : 0)
				 + (hasDirectDebitDiscount ? (priceWithDiscount * (directDebitDiscount / 100)) : 0);
			orderItem.parentDiscountId = orderItem.parentDiscount != 0 ? accountDiscount.Id : null;
		}

		if (partnerDiscountMap.containsKey(orderItem.productId)) {
			accountDiscount = partnerDiscountMap.get(orderItem.productId);
			accountDiscount.Product_Discount__c = accountDiscount.Product_Discount__c == null ? 0 : accountDiscount.Product_Discount__c;
			accountDiscount.BID_Price__c = accountDiscount.BID_Price__c == null ? 0 : accountDiscount.BID_Price__c;
			Decimal discount = accountDiscount.Product_Discount__c + accountDiscount.BID_Price__c;
			Decimal priceWithDiscount = orderItem.listPrice - discount;

			orderItem.partnerDiscount = discount + (hasOverridingDiscount ? (priceWithDiscount * (overridingDiscount / 100)) : 0)
				 + (hasDirectDebitDiscount ? (priceWithDiscount * (directDebitDiscount / 100)) : 0);
			orderItem.partnerDiscountId = orderItem.partnerDiscount != 0 ? accountDiscount.Id : null;
		}

		if (orderItem.partnerDiscountId != null || orderItem.parentDiscountId != null) {
			orderItem.discountToApply = orderItem.partnerDiscountId != null && (orderItem.partnerDiscount > orderItem.parentDiscount) ? 'Partner' : 'Account';
		}
	}

	@AuraEnabled
	public static List<OrderItemData> addAdditionalCharges(AdditionalCharges.OrderData orderData) {
		List<AdditionalCharges.OrderItemData> additionalCharges = AdditionalCharges.process(orderData);
		List<OrderItemData> orderItems = new List<OrderItemData>();

		for (AdditionalCharges.OrderItemData additionalCharge : additionalCharges) {
			OrderItemData orderItem = new OrderItemData();
			orderItem.rowKey = 'new-' + System.now() + Math.random();
			orderItem.pricebookEntryId = additionalCharge.pricebookEntryId;
			orderItem.productId = additionalCharge.productId;
			orderItem.manualproductname = additionalCharge.productName;
			orderItem.listprice = additionalCharge.unitPrice;
			orderItem.vatRate = additionalCharge.vatRate;
			orderItem.quantity = additionalCharge.quantity;
			orderItem.supplierId = FIRST_MILE_SUPPLIER.Id;
			orderItem.supplierName = 'First Mile Ltd';
			orderItems.add(orderItem);
		}

		return orderItems;
	}

	// To calculate the totalPrice for all the orderItems (Calculation happens in the OrderItemData wrapper)
	@AuraEnabled
	public static OrderData calculateTotals(OrderData orderData) {
		orderData.totalPrice = 0;
		for (OrderItemData orderItem : orderData.orderItems) {
			orderData.totalPrice += orderItem.totalPrice;
		}

		orderData.vat = Vat.calculate(orderData.orderItems);

		return orderData;
	}

	@AuraEnabled
	public static String saveOrder(OrderData orderData) {
		Savepoint sp = Database.setSavepoint();
		try {
			Order orderToSave = new Order();
			orderToSave.AccountId = orderData.locationId;
			orderToSave.Type = orderData.type;
			orderToSave.Contact__c = orderData.contactId;
			orderToSave.PO_Number__c = orderData.poNumber;
			orderToSave.Requested_Delivery_Date__c = Date.valueOf(orderData.requestedDeliveryDate);
			orderToSave.Driver_Notes__c = orderData.deliveryNotes;
			orderToSave.EffectiveDate = System.today();
			orderToSave.Status = (orderToSave.Type == 'Contractor') ? 'Delayed Confirmation' : 'Draft';
			orderToSave.IsFuelSurchargeEvaluated__c = true;

			if (orderData.isPaymentConfirmed) {
				orderToSave.Confirm_Payment__c = true;
				orderToSave.Who_confirmed_the_Payment__c = UserInfo.getFirstName() + UserInfo.getLastName();
			}

			INSERT orderToSave;

			Set<Id> subscribedProductIds = new Set<Id>();
			List<OrderItem> orderItems = new List<OrderItem>();
			for (OrderItemData item : orderData.orderItems) {
				OrderItem orderItem = new OrderItem();
				orderItem.OrderId = orderToSave.Id;
				orderItem.PricebookEntryId = item.pricebookentryid;
				orderItem.Quantity = item.quantity;
				orderItem.ListPrice__c = item.listPrice;
				orderItem.Supplier_Unit_Price__c = item.supplierUnitPrice;
				orderItem.unitPrice = item.unitPrice;
				orderItem.Manual_Product_Name__c = item.manualProductName;
				orderItem.Discount_to_Apply__c = item.discountToApply;
				orderItem.Supplier__c = item.supplierId;
				orderItem.Price_Book__c = orderData.priceBookId;
				orderItem.Product2Id = item.productId;
				orderItem.Quantity_Sold_In__c = item.quantitysoldin;
				orderItem.Total_Discount__c = item.discount;
				if (item.discountToApply == 'Account') {
					orderItem.Discount__c = item.discount;
					orderItem.Account_Discount__c = item.parentDiscountId;
				} else if (item.discountToApply == 'Partner') {
					orderItem.Partner_Discount__c = item.discount;
					orderItem.Account_Discount__c = item.partnerDiscountId;
				}

				orderItems.add(orderItem);
				if (item.discountToApply == 'Partner' && item.subscribedProductId != null) {
                    subscribedProductIds.add(item.subscribedProductId);
				}
			}

			INSERT orderItems;

			if (orderToSave.Type != 'Contractor') {
				orderToSave.Status = 'Confirmed';
				UPDATE orderToSave;
			}

			if (!subscribedProductIds.isEmpty()) {
				List<Subscribed_Products__c> subscribedProducts = new List<Subscribed_Products__c>();
				for (Id subscribedProductId : subscribedProductIds) {
					subscribedProducts.add(new Subscribed_Products__c(Id = subscribedProductId, Last_Discount_Given__c = Date.today()));
				}

				UPDATE subscribedProducts;
			}

			return ordertoSave.Id;

		} catch (Exception e) {
			Database.rollback(sp);
			throw new AuraHandledException('Error saving order items: ' + e.getMessage());
		}
	}

	private static Map<Id, Suppliers__c> getProductSupplierMap(Set<Id> productIds, String locationId, Map<Id, Subscribed_Products__c> subscribedProductMap) {
		Map<Id, Suppliers__c> productSupplierMap = new Map<Id, Suppliers__c>();

		if (productIds.isEmpty()) return productSupplierMap;

		for (Subscribed_Products__c subscribedProduct : subscribedProductMap.values()) {
			productSupplierMap.put(subscribedProduct.Product__c, new Suppliers__c(Id = subscribedProduct.Supplier__c, Name = subscribedProduct.Supplier__r.Name));
		}

		for (OrderItem orderItem : [SELECT Product2Id, Supplier__c, Supplier__r.Name FROM OrderItem WHERE Product2Id IN :productIds AND CreatedDate >= LAST_N_MONTHS:12
		AND (Order.AccountId = :locationId OR Location__c = :locationId) AND Product2.Product_Type__c = 'Delivery' AND Supplier__c != null AND Supplier__r.Supplier_Active__c = true
		ORDER BY CreatedDate DESC]) {
			if (!productSupplierMap.containsKey(orderItem.Product2Id)) {
				productSupplierMap.put(orderItem.Product2Id, new Suppliers__c(Id = orderItem.Supplier__c, Name = orderItem.Supplier__r.Name));
			}
		}

		for (Id productId : productIds) {
			if (!productSupplierMap.containsKey(productId)) {
				productSupplierMap.put(productId, FIRST_MILE_SUPPLIER);
			}
		}

		return productSupplierMap;
	}
}