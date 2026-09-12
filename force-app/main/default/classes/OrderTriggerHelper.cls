/** /**
(c) 2018 XPAND-IT - Braga
Developed by XPAND-IT
@date Date of creation: unknown
Date of updates: 12.2018 - December 2018
@author Bruno, Jéssica and Nuno RS / XPAND-IT | Previous authors: unknown

@modifications 18.12.2018 [Invoices JIRA - update] 1107 - Exceptional Monotoring
@modifications 12.12.2018 [Invoices JIRA - update] 950 - Beth required to remove the last working day and use last day instead.
@modifications 01.02.2022 "Order Save behaviour" release - make necessary changes
*/
public with sharing class OrderTriggerHelper {

	//Added on 28.11.2018
	public static void updateInsertedAsDelivered(List<Order> list_StatusIsDelivered) {
		//List only comes for Orders that have Status == Delivered.
		for (Order o: list_StatusIsDelivered) {
			o.InsertedAsDelivered__c = true;
		}
	}

	//START After insert, 1079. Update OrderNumber.
	public static void updateOrderNumber(List<Order> newList) {
		system.debug('Update Enqix ID on Order');
		system.debug(newList);
		//Bruno 05-12-2018 - No need for the query on OrderNumber != null because the field is never null
		List<Order> orders = [SELECT id, Enqix_Id__c, OrderNumber, AccountId FROM Order WHERE Id in: newList];
		//WHERE Enqix_Id__c != null removed from the query.

		String orderNumberwithoutZeroes;
		for (Order o: orders) {
			system.debug(o.Enqix_Id__c);
			orderNumberwithoutZeroes = o.OrderNumber.replaceFirst('^0+', '');
			system.debug('orderNumberwithoutZeroes' + orderNumberwithoutZeroes);
			o.Enqix_Id__c = orderNumberwithoutZeroes;
			system.debug(o.Enqix_Id__c);
		}
		//update orders;

		Database.SaveResult[] resultsOS = Database.update(orders, false);
		LogRegister.createLogsUpsert(resultsOS, orders, 'OrderTriggerHelper update orders', 'Update', 'Order', 'AccountId');
	}

    //Insert OrderProducts related to the Recurring orders inserted by the batch process "RecurringBatch"
	public static void insertOrderProductsForRecurrings(List<Order> newOrders) {
		List<OrderItem> orderLinesToInsert = new List<OrderItem>();
		Set<Id> oIds = new Set<Id>();
		Set<Id> locationIds = new Set<Id>();
		Set<Id> parentIds = new Set<Id>();
		Set<Id> partnerIds = new Set<Id>();
		Set<Id> accountPricebookIds = new Set<Id>();
		Map<string, Account_Discount__c> accProdDiscountMap = new Map<string, Account_Discount__c>();

		for (Order o : newOrders) {
			oIds.add(o.Id);
			locationIds.add(o.AccountId);
		}
		for (Order ord : [SELECT Id,
						  Account.ParentId,
						  Account.Partnership__c From Order where Id In :oIds
						 ]) {
							 parentIds.add(ord.Account.ParentId);
							 partnerIds.add(ord.Account.Partnership__c);
						 }
		//Jira 1755 --> Fix Recurring Batch - Nuno
		//JIRA JIRA 1487 - no Account Discount Overlapping
		for (Account_Discount__c ad : [
			SELECT Id,
			Account__c,
			RecordType.Name,
			Product__c,
			Product_Discount__c,
			BID_Price__c,
			Gross_Price_f__c,
			Location_Price__c FROM Account_Discount__c WHERE DiscountSupStartDate__c <= TODAY AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null) AND (Account__c IN:parentIds OR Account__c IN:partnerIds)
		]) {
			string key = ad.Account__c + '-' + ad.Product__c + '-' + ad.RecordType.Name;
			accProdDiscountMap.put(key, ad);
		}

		Map<Id, List<WasteDestination__c>> facilityToWasteDestinationsMap = new Map<Id, List<WasteDestination__c>>();
		for (
			Recurrings__c r : [SELECT Price_Book__c, Account__r.Price_Book__c, Facility__c FROM Recurrings__c WHERE Account__c IN: locationIds]
		) {
			if (!Test.isRunningTest()) {
				accountPricebookIds.add(r.Account__r.Price_Book__c);
			} else {
				accountPricebookIds.add(r.Price_Book__c);
			}

			if (r.Facility__c != null && !facilityToWasteDestinationsMap.containsKey(r.Facility__c)) {
				facilityToWasteDestinationsMap.put(r.Facility__c, new List<WasteDestination__c>());
			}
		}

		if (!facilityToWasteDestinationsMap.isEmpty()) {
			for (WasteDestination__c wasteDestination : [SELECT Facility__c, ServiceType__c, ServiceSubtype__c FROM WasteDestination__c WHERE Facility__c IN :facilityToWasteDestinationsMap.keySet() AND IsActiveToday__c = true]) {
				facilityToWasteDestinationsMap.get(wasteDestination.Facility__c).add(wasteDestination);
			}
		}

		Map<Id, Pricebook2> allPbs = new Map<Id, Pricebook2>([
			SELECT Id,
			(SELECT Product2Id, UnitPrice FROM PricebookEntries)FROM Pricebook2 WHERE Id IN: accountPricebookIds
		]);

		Date TODAY = Date.today();

		for (Order o : [
			SELECT Id,
			AccountId,
			Account.ParentId,
			Account.Partnership__c,
			Account.Price_Book__c,
			RecurringId__r.Discount_to_Apply__c,
			RecurringId__r.Supplier__c,
			RecurringId__r.Product__c,
			RecurringId__r.Product__r.Product_Type__c,
			RecurringId__r.Product__r.Service_Type__c,
			RecurringId__r.Product__r.Service_Subtype__c,
			RecurringId__r.Facility__c,
			RecurringId__r.Price_Book__c,
			RecurringId__r.ManualPrice__c,
			RecurringId__r.Supplier_Unit_Price__c,
			RecurringId__r.Quantity__c FROM Order WHERE Id IN: oIds
		]) {
			OrderItem op = new OrderItem();
			op.OrderId = o.Id;
			op.Location__c = o.AccountId;
			if (o.RecurringId__r.Product__r.Product_Type__c == 'Collection') {
				op.CollectionDate__c = TODAY;
			}
			op.Discount_to_Apply__c = o.RecurringId__r.Discount_to_Apply__c;
			op.Product2Id = o.RecurringId__r.Product__c;
			if (!Test.isRunningTest()) {
				op.Price_Book__c = o.Account.Price_Book__c;
			} else {
				op.Price_Book__c = o.RecurringId__r.Price_Book__c;
			}
			op.Supplier__c = o.RecurringId__r.Supplier__c;
			Pricebook2 usedPricebook = allPbs.get(op.Price_Book__c);

			for (PricebookEntry pbe : usedPricebook.PricebookEntries) {
				if (op.Product2Id == pbe.Product2Id) {
					op.ListPrice__c = pbe.UnitPrice;
					op.PricebookEntryId = pbe.Id;
					break;
				}
			}
			op.Quantity = o.RecurringId__r.Quantity__c;

			if (o.RecurringId__r.ManualPrice__c != null) {
				op.ListPrice__c = o.RecurringId__r.ManualPrice__c;
			}
			op.Supplier_Unit_Price__c = o.RecurringId__r.Supplier_Unit_Price__c;

			if (op.Discount_to_Apply__c == 'Account') {
				string opkeyacc = o.Account.ParentId + '-' + op.Product2Id + '-AccountDiscount';
				if (accProdDiscountMap.containsKey(opkeyacc)) {
					op.Discount__c = accProdDiscountMap.get(opkeyacc).Product_Discount__c;
				}
				op.Discount__c = op.Discount__c == null ? 0 : op.Discount__c;
			} else if (op.Discount_to_Apply__c == 'Partner') {
				string opkeypart = o.Account.Partnership__c + '-' + op.Product2Id + '-PartnerDiscount';
				if (accProdDiscountMap.containsKey(opkeypart)) {
					Decimal productDiscount = accProdDiscountMap.get(opkeypart).Product_Discount__c == null ? 0 : accProdDiscountMap.get(opkeypart).Product_Discount__c;
					Decimal bidPrice = accProdDiscountMap.get(opkeypart).BID_Price__c == null ? 0 : accProdDiscountMap.get(opkeypart).BID_Price__c;
					op.Partner_Discount__c = productDiscount + bidPrice;
				}
				op.Partner_Discount__c = op.Partner_Discount__c == null ? 0 : op.Partner_Discount__c;
			}

			if (facilityToWasteDestinationsMap.containsKey(o.RecurringId__r.Facility__c)) {
				for (WasteDestination__c wasteDestination : facilityToWasteDestinationsMap.get(o.RecurringId__r.Facility__c)) {
					if (wasteDestination.ServiceType__c == o.RecurringId__r.Product__r.Service_Type__c && wasteDestination.ServiceSubtype__c == o.RecurringId__r.Product__r.Service_Subtype__c) {
						op.WasteDestination__c = wasteDestination.Id;
						break;
					}
				}
			}

			orderLinesToInsert.add(op);
		}

		if (orderLinesToInsert.size() > 0){
			orderLinesToInsert.addAll(addAdditionalCharges(orderLinesToInsert));

			Database.SaveResult[] resultsOL = Database.insert(orderLinesToInsert, false);
			LogRegister.createLogsUpsert(resultsOL, orderLinesToInsert, 'OrderTriggerHelper insert OrderLines', 'Insert', 'OrderItem', 'OrderId');
		}
	}

	private static List<OrderItem> addAdditionalCharges(List<OrderItem> orderItems) {
		Id firstMileSupplierId = [SELECT Id FROM Suppliers__c WHERE IsExternal__c = false LIMIT 1].Id;
		Map<Id, List<OrderItem>> orderToOrderItemsMap = new Map<Id, List<OrderItem>>();

		for (OrderItem orderItem : orderItems) {
			if (orderToOrderItemsMap.containsKey(orderItem.OrderId)) {
				orderToOrderItemsMap.get(orderItem.OrderId).add(orderItem);
			} else {
				orderToOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>{orderItem});
			}
		}

		List<OrderItem> chargeOrderItems = new List<OrderItem>();
		for (Id orderId : orderToOrderItemsMap.keySet()) {
			AdditionalCharges.OrderData orderData = new AdditionalCharges.OrderData();
			orderData.locationId = orderToOrderItemsMap.get(orderId)[0].Location__c;
			orderData.orderItems = new List<AdditionalCharges.OrderItemData>();
			for (OrderItem orderItem : orderToOrderItemsMap.get(orderId)) {
				Decimal discount = orderItem.Discount_to_Apply__c == null ? 0 : orderItem.Discount_to_Apply__c == 'Partner' ? orderItem.Partner_Discount__c : orderItem.Discount__c;
				AdditionalCharges.OrderItemData orderItemData = new AdditionalCharges.OrderItemData();
				orderItemData.productId = orderItem.Product2Id;
				orderItemData.quantity = orderItem.Quantity;
				orderItemData.unitPrice = orderItem.ListPrice__c - discount;
				orderData.orderItems.add(orderItemData);
			}

			List<AdditionalCharges.OrderItemData> additionalCharges = AdditionalCharges.process(orderData);
			for (AdditionalCharges.OrderItemData additionalCharge : additionalCharges) {
				OrderItem orderItem = new OrderItem();
				orderItem.OrderId = orderId;
				orderItem.Product2Id = additionalCharge.productId;
				orderItem.PricebookEntryId = additionalCharge.pricebookEntryId;
				orderItem.Manual_Product_Name__c = additionalCharge.productName;
				orderItem.Quantity = additionalCharge.quantity;
				orderItem.ListPrice__c = orderItem.unitPrice = additionalCharge.unitPrice;
				orderItem.Discount_to_Apply__c = 'Account';
				orderItem.Supplier__c = firstMileSupplierId;
				orderItem.Quantity_Sold_In__c = 1;
				orderItem.Total_Discount__c = orderItem.Discount__c = 0;
				chargeOrderItems.add(orderItem);
			}
		}

		return chargeOrderItems;
	}

	//TODO JIRA 965 - create secure descruction compliance docs
	@future
	public static void createSecureDestructionsFuture(Set<Id> orderIds) {
		createSecureDestructions(orderIds);
	}

	public static void createSecureDestructions(Set<Id> orderIds) {
		/*Set<Id> orderIds = new Set<Id>();
		for (Order o: orders) {
			orderIds.add(o.Id);
		}*/
		/*List<Order> orderWithOrderLines = [SELECT Id, AccountId, Account.Name,
			(SELECT Id, Product2.Product_Skins__r.Name FROM OrderItems where Product2.Product_Skins__r.Name LIKE '%Sec Destr%')
			FROM Order where Id in: orderIds AND Id in (SELECT OrderId FROM OrderItem where Product2.Product_Skins__r.Name LIKE '%Sec Destr%')
		];*/

		//system.debug(orderWithOrderLines);
		//Create RecordType.Name = 'Consignment Notes'
		//Asked "a compliance document with new record type ‘secure destruction note’ should be created AFTER 24 hours."
		//Asked - create a Document for each Order Product / Order Item.

		//Vou precisar de criar uma workflow rule para fazer isto -> regra no OrderItem, verificar alteração de estado da Order (PRIORVALUE)
		// se o Product2.Name contém (CONTAINS) o LIKE da query

		List<Compliance_Doc__c> secDocstoCreate = new List<Compliance_Doc__c>();

		for (Order o: [SELECT Id, AccountId, Account.Name,
				(SELECT Id, Product2.Product_Skins__r.Name FROM OrderItems WHERE OrderId IN :orderIds AND Product2.Product_Skins__r.Name LIKE '%Sec Destr%')
				FROM Order where Id in: orderIds AND Id in (SELECT OrderId FROM OrderItem WHERE OrderId IN :orderIds AND Product2.Product_Skins__r.Name LIKE '%Sec Destr%')
				]) {
			Compliance_Doc__c doc = new Compliance_Doc__c();
			doc.Account__c = o.AccountId;
			doc.Order__c = o.Id;
			string todaysdate = System.today().year() + '-' + System.today().month() + '-' + System.today().day();
			doc.Name = 'Secure Destruction Certificate ' + todaysdate;
			doc.Status__c = 'Draft';
			doc.RecordTypeId = Schema.SObjectType.Compliance_Doc__c.getRecordTypeInfosByName().get('Secure Destruction Certificate').getRecordTypeId();
			doc.Generated_on_Salesforce__c = true;
			secDocstoCreate.add(doc);
		}
		system.debug('Docs to create Secure D.Note :: ' + secDocstoCreate.size());
		//insert secDocstoCreate;

		Database.SaveResult[] resultsOS = Database.insert(secDocstoCreate, false);
		LogRegister.createLogsUpsert(resultsOS, secDocstoCreate, 'OrderTriggerHelper insert Compliance Documents', 'Insert', 'Compliance_Doc__c', 'Account__c');

	}
}