public without sharing class AdditionalChargesImpl {

	private static final Boolean DELIVERY_CHARGE_ACTIVE;
	private static final Id BAG_DELIVERY_CHARGE_PRODUCT;
	private static final Id BIN_DELIVERY_CHARGE_PRODUCT;
	private static final String BAG_CONTAINER_NAMES;
	private static final String BIN_CONTAINER_NAMES;
	private static final Boolean FUEL_SURCHARGE_ACTIVE;
	private static final Id FUEL_SURCHARGE_PRODUCT;
	private static final Decimal FUEL_SURCHARGE;
	static {
		AdditionalChargeSetting__c additionalChargeSetting = AdditionalChargeSetting__c.getOrgDefaults();
		DELIVERY_CHARGE_ACTIVE = additionalChargeSetting.IsDeliveryChargeActive__c;
		BAG_DELIVERY_CHARGE_PRODUCT = additionalChargeSetting.BagDeliveryChargeProduct__c;
		BIN_DELIVERY_CHARGE_PRODUCT = additionalChargeSetting.BinDeliveryChargeProduct__c;
		BAG_CONTAINER_NAMES = additionalChargeSetting.BagContainerNames__c;
		BIN_CONTAINER_NAMES = additionalChargeSetting.BinContainerNames__c;
		FuelSurchargeSetting__c fuelSurchargeSetting = FuelSurchargeSetting__c.getOrgDefaults();
		FUEL_SURCHARGE_ACTIVE = fuelSurchargeSetting.IsActive__c;
		FUEL_SURCHARGE_PRODUCT = fuelSurchargeSetting.ProductId__c;
		FUEL_SURCHARGE = fuelSurchargeSetting.Surcharge__c;
	}

	public List<AdditionalCharges.OrderItemData> addWTNCharge(AdditionalCharges.OrderData orderData) {
		//check and add WTN and Delivery Charge Order Items
		return new List<AdditionalCharges.OrderItemData>();
	}

	public List<AdditionalCharges.OrderItemData> addDeliveryCharge(AdditionalCharges.OrderData orderData, List<AdditionalCharges.OrderItemData> additionalCharges) {
		if (!DELIVERY_CHARGE_ACTIVE) {
			return new List<AdditionalCharges.OrderItemData>();
		}

		Set<Id> productIds = new Set<Id>();
		Decimal totalAmount = 0;
		for (AdditionalCharges.OrderItemData orderItem : orderData.orderItems) {
			productIds.add(orderItem.productId);
			totalAmount += (orderItem.unitPrice * orderItem.quantity);
		}
		for (AdditionalCharges.OrderItemData orderItem : additionalCharges) {
			totalAmount += (orderItem.unitPrice * orderItem.quantity);
		}

		List<String> bagContainers = StringUtil.splitTrim(BAG_CONTAINER_NAMES, ',');
		List<String> binContainers = StringUtil.splitTrim(BIN_CONTAINER_NAMES, ',');
		Boolean bagProductExist = false, binProductExist = false;

		String containerType;
		for (AggregateResult aggregateResult : [SELECT Container_Type__r.Name name FROM Product2 WHERE Id IN :productIds AND (Container_Type__r.Name IN :bagContainers OR Container_Type__r.Name IN :binContainers) GROUP BY Container_Type__r.Name]) {
			containerType = (String)aggregateResult.get('name');
			if (binContainers.contains(containerType)) {
				binProductExist = true;
			} else {
				bagProductExist = true;
			}
		}

		if (!bagProductExist && !binProductExist) {
			return new List<AdditionalCharges.OrderItemData>();
		}

		Account location = [SELECT IsDeliveryChargeExemptLocation__c, IsVatExemptLocation__c, Price_Book__c FROM Account WHERE Id = :orderData.locationId];
		Boolean applyDeliveryCharge = !(location.IsDeliveryChargeExemptLocation__c || totalAmount > 10000);
		Map<Id, PricebookEntry> productToPriceMap = new Map<Id, PricebookEntry>();

		for (PricebookEntry pricebookEntry : [SELECT Product2Id, UnitPrice, Product2.Name, Product2.IsVatExempt__c FROM PricebookEntry WHERE PriceBook2Id = :location.Price_Book__c AND (Product2Id = :BAG_DELIVERY_CHARGE_PRODUCT OR Product2Id = :BIN_DELIVERY_CHARGE_PRODUCT)]) {
			productToPriceMap.put(pricebookEntry.Product2Id, pricebookEntry);
		}

		List<AdditionalCharges.OrderItemData> orderItems = new List<AdditionalCharges.OrderItemData>();

		if (binProductExist) {
			PricebookEntry pricebookEntry = productToPriceMap.get(BIN_DELIVERY_CHARGE_PRODUCT);
			AdditionalCharges.OrderItemData orderItem = createOrderItem(pricebookEntry, location.IsVatExemptLocation__c, applyDeliveryCharge ? pricebookEntry.UnitPrice : 0);
			orderItems.add(orderItem);
			totalAmount += (orderItem.unitPrice * orderItem.quantity);
		}

		applyDeliveryCharge = !(location.IsDeliveryChargeExemptLocation__c || totalAmount > 10000);
		if (bagProductExist) {
			PricebookEntry pricebookEntry = productToPriceMap.get(BAG_DELIVERY_CHARGE_PRODUCT);
			orderItems.add(createOrderItem(pricebookEntry, location.IsVatExemptLocation__c, applyDeliveryCharge ? pricebookEntry.UnitPrice : 0));
		}

		return orderItems;
	}

	public List<AdditionalCharges.OrderItemData> addFuelSurcharge(AdditionalCharges.OrderData orderData) {
		if (!FUEL_SURCHARGE_ACTIVE) {
			return new List<AdditionalCharges.OrderItemData>();
		}

		Account location = [SELECT IsFuelSurchargeExemptLocation__c, IsVatExemptLocation__c, Price_Book__c FROM Account WHERE Id = :orderData.locationId];
		if (location.IsFuelSurchargeExemptLocation__c) {
			return new List<AdditionalCharges.OrderItemData>();
		}

		Set<Id> productIds = new Set<Id>();
		for (AdditionalCharges.OrderItemData orderItem : orderData.orderItems) {
			productIds.add(orderItem.productId);
		}

		Map<Id, Product2> productMap = new Map<Id, Product2>([SELECT IncludeFuelSurcharge__c FROM Product2 WHERE Id IN :productIds AND IncludeFuelSurcharge__c = true]);
		if (productMap.isEmpty()) {
			return new List<AdditionalCharges.OrderItemData>();
		}
		Decimal totalPrice = 0;
		for (AdditionalCharges.OrderItemData orderItem : orderData.orderItems) {
			if (productMap.containsKey(orderItem.productId)) {
				totalPrice += orderItem.unitPrice * orderItem.quantity;
			}
		}

		PricebookEntry pricebookEntry = [SELECT Product2Id, Product2.Name, Product2.IsVatExempt__c FROM PricebookEntry WHERE PriceBook2Id = :location.Price_Book__c AND Product2Id = :FUEL_SURCHARGE_PRODUCT];
		return new List<AdditionalCharges.OrderItemData>{createOrderItem(pricebookEntry, location.IsVatExemptLocation__c, Math.max(((totalPrice * FUEL_SURCHARGE) / 100).setScale(2), 0))};
	}

	private AdditionalCharges.OrderItemData createOrderItem(PricebookEntry pricebookEntry, Boolean isVatExemptLocation, Decimal unitPrice) {
		AdditionalCharges.OrderItemData orderItem = new AdditionalCharges.OrderItemData();
		orderItem.productId = pricebookEntry.Product2Id;
		orderItem.pricebookEntryId = pricebookEntry.Id;
		orderItem.productName = pricebookEntry.Product2.Name;
		orderItem.vatRate = (pricebookEntry.Product2.IsVatExempt__c || isVatExemptLocation) ? 0 : Vat.DEFAULT_VAT_RATE;
		orderItem.quantity = 1;
		orderItem.unitPrice = unitPrice;
		return orderItem;
	}
}