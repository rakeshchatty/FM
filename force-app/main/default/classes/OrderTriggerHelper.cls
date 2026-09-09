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
		for (
			Recurrings__c r : [SELECT Price_Book__c,Account__r.Price_Book__c FROM Recurrings__c WHERE Account__c IN: locationIds]
		) {
			if (!Test.isRunningTest()) {
				accountPricebookIds.add(r.Account__r.Price_Book__c);
			} else {
				accountPricebookIds.add(r.Price_Book__c);
			}
		}
		system.debug('recurringPriceBooks' + accountPricebookIds);
		Map<Id, Pricebook2> allPbs = new Map<Id, Pricebook2>([
			SELECT Id,
			(SELECT Product2Id, UnitPrice FROM PricebookEntries)FROM Pricebook2 WHERE Id IN: accountPricebookIds
		]);
		system.debug(allPbs);
		for (Order o : [
			SELECT Id,
			Account.ParentId,
			Account.Partnership__c,
			Account.Price_Book__c,
			RecurringId__r.Discount_to_Apply__c,
			RecurringId__r.Supplier__c,
			RecurringId__r.Product__c,
			RecurringId__r.Price_Book__c,
			RecurringId__r.Quantity__c FROM Order WHERE Id IN: oIds
		]) {
			System.debug(o.Account.Price_book__c);
			OrderItem op = new OrderItem();
			op.OrderId = o.Id;
			if(o.RecurringId__r.Discount_to_Apply__c == null){
				op.Discount_to_Apply__c = 'Account';
			} else {
				op.Discount_to_Apply__c = o.RecurringId__r.Discount_to_Apply__c;
			}
			System.debug('op.Discount_to_Apply__c' + op.Discount_to_Apply__c);
			op.Product2Id = o.RecurringId__r.Product__c;
			if (!Test.isRunningTest()) {
				op.Price_Book__c = o.Account.Price_Book__c;
			} else {
				op.Price_Book__c = o.RecurringId__r.Price_Book__c;
			}
			op.Supplier__c = o.RecurringId__r.Supplier__c;
			Pricebook2 usedPricebook = allPbs.get(op.Price_Book__c);
			system.debug('used pricebook' + usedPricebook + ' order product2: ' + op);

			//if(usedPricebook.PricebookEntries.size() != 0){ }
			for (PricebookEntry pbe : usedPricebook.PricebookEntries) {
				if (op.Product2Id == pbe.Product2Id) {
					op.ListPrice__c = pbe.UnitPrice;
					op.PricebookEntryId = pbe.Id;
					system.debug('pbe.UnitPrice --> '+pbe.UnitPrice);
					system.debug('ListPrice__c --> '+op.ListPrice__c);
				}
			}
			op.Quantity = o.RecurringId__r.Quantity__c;
			if (op.Discount_to_Apply__c == 'Account') {
				string opkeyacc = o.Account.ParentId + '-' + op.Product2Id + '-AccountDiscount';
				if (accProdDiscountMap.containsKey(opkeyacc)) {
					op.Discount__c = accProdDiscountMap.get(opkeyacc).Product_Discount__c;
				}
			} else if (op.Discount_to_Apply__c == 'Partner') {
				string opkeypart = o.Account.Partnership__c + '-' + op.Product2Id + '-PartnerDiscount';
				if (accProdDiscountMap.containsKey(opkeypart)) {
					Decimal productDiscount = accProdDiscountMap.get(opkeypart).Product_Discount__c == null ? 0 : accProdDiscountMap.get(opkeypart).Product_Discount__c;
					Decimal bidPrice = accProdDiscountMap.get(opkeypart).BID_Price__c == null ? 0 : accProdDiscountMap.get(opkeypart).BID_Price__c;
					op.Partner_Discount__c = productDiscount + bidPrice;
				}
			}
			system.debug('orderLinesToInsert --> '+orderLinesToInsert.size());
			orderLinesToInsert.add(op);
		}

		if (orderLinesToInsert.size() > 0){
			Database.SaveResult[] resultsOL = Database.insert(orderLinesToInsert, false);
			LogRegister.createLogsUpsert(resultsOL, orderLinesToInsert, 'OrderTriggerHelper insert OrderLines', 'Insert', 'OrderItem', 'OrderId');
		}
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

	//JIRA 964 - creation of Consignment Notes
	@future
	public static void createConsignmentNotesFuture(Set<Id> orderIds) {
		createConsignmentNotes(orderIds);
	}

	public static void createConsignmentNotes(Set<Id> orderIds) {
		Set<Id> accountIds = new Set<Id>();

		List<Order> orderWithOrderLines = [SELECT Id, AccountId, Account.Name, (SELECT Id, Product2Id, Product2.Product_Skins__r.Name FROM OrderItems WHERE OrderId IN :orderIds AND (Product2.Product_Skins__r.Name LIKE '%WEEE%' OR
				Product2.Product_Skins__r.Name LIKE '%Fluro%' OR Product2.Product_Skins__r.Name LIKE '%Batteries%')) FROM Order where Id in: orderIds AND Id IN(SELECT OrderId FROM OrderItem WHERE OrderId IN :orderIds AND (Product2.Product_Skins__r.Name LIKE '%WEEE%'
				OR Product2.Product_Skins__r.Name LIKE '%Batteries%' OR Product2.Product_Skins__r.Name LIKE '%Fluro%'))];

		for (Order o: orderWithOrderLines) {
			accountIds.add(o.AccountId);
		}

		List<Compliance_Doc__c> mostRecentCN = [SELECT Order__c, Account__c, ConsignmentNote_Code__c FROM Compliance_Doc__c WHERE Account__c IN: accountids AND RecordType.Name = 'Consignment Notes'
			ORDER BY Name desc
		];
		//system.debug(orderWithOrderLines);
		system.debug(mostRecentCN);

		Map<String, String> mostRecentCNmap = new Map<String, String>();
		for (Compliance_Doc__c cd: mostRecentCN) {
			string key = cd.Account__c;
			if (!mostRecentCNmap.containsKey(key)) {
				mostRecentCNmap.put(key, cd.ConsignmentNote_Code__c);
			}
		}

		List<Compliance_Doc__c> consigNotesToCreate = new List<Compliance_Doc__c>();

		for (Order o: orderWithOrderLines) {
			for (OrderItem oi: o.OrderItems) {
				system.debug(oi);
				string key = o.AccountId;
				string mostRecentCode;
				Integer uniquedigitcode;
				if (mostRecentCNmap.containsKey(key)) {
					mostRecentCode = mostRecentCNmap.get(key);
					uniquedigitcode = Integer.valueOf(mostRecentCode.substringAfter('CN'));
					uniquedigitcode = uniquedigitcode + 1;
					mostRecentCNmap.remove(key);
					mostRecentCode = mostRecentCode.substring(0, 9) + uniquedigitcode;
					system.debug(mostRecentCode);
					mostRecentCNmap.put(key, mostRecentCode);
					system.debug(uniquedigitcode);
				}
				Compliance_Doc__c cn = new Compliance_Doc__c();
				string loc = '';
				try {
					loc = o.Account.Name.substring(0, 6).toUpperCase();
				} catch (Exception e) {
					loc = o.Account.Name.toUpperCase();
				}
				system.debug(loc);

				if (uniquedigitcode != null) {
					if (uniquedigitcode < 10) {
						cn.ConsignmentNote_Code__c = loc + '/CN00' + uniquedigitcode;
						cn.Name = loc + '/CN00' + uniquedigitcode;
					} else if (uniquedigitcode < 100 && uniquedigitcode >= 10) {
						cn.ConsignmentNote_Code__c = loc + '/CN0' + uniquedigitcode;
						cn.Name = loc + '/CN0' + uniquedigitcode;
					} else {
						cn.ConsignmentNote_Code__c = loc + '/CN' + uniquedigitcode;
						cn.Name = loc + '/CN' + uniquedigitcode;
					}
					uniquedigitcode = uniquedigitcode + 1;
				} else {
					cn.ConsignmentNote_Code__c = loc + '/CN001';
					cn.Name = loc + '/CN001';
					mostRecentCNmap.put(o.AccountId, cn.Name);
				}
				cn.RecordTypeId = Schema.SObjectType.Compliance_Doc__c.getRecordTypeInfosByName().get('Consignment Notes').getRecordTypeId();
				cn.Account__c = o.AccountId;
				cn.Order__c = o.Id;
				cn.ConsignmentNote_PremisesCode__c = 'Exempt';
				cn.ConsignmentNote_ProcessGivingWaste__c = 'End of Life EEE';
				cn.Product__c = oi.Product2Id;
				cn.Generated_on_Salesforce__c = true;
				consigNotesToCreate.add(cn);
			}
		}

		system.debug(consigNotesToCreate);
		//insert consigNotesToCreate;

		Database.SaveResult[] resultsCN = Database.insert(consigNotesToCreate, false);
		LogRegister.createLogsUpsert(resultsCN, consigNotesToCreate, 'OrderTriggerHelper insert Consignment Documents', 'Insert', 'ConsignmentNote_Code__c', 'Account__c');
	}
}