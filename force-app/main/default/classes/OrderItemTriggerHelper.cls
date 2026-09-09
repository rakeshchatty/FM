/**
(c) 2018 XPAND-IT / Rolling-Space
Developed by XPAND-IT, Braga (Portugal)
@date Date of creation unknown
@author Bruno Mendes, Jéssica Pereira and others

@description Every time an Order Item gets inserted / updated (before / after) / deleted (before), it does something...
@modifications 07.01.2019 [Invoices JIRA - update] 1107 - Exceptional Monotoring
@modifications 07.01.2019 [Invoices JIRA 950] - 1227] - Keep Partner BID Invoices commented. New Class created to fulfill 1227.
@modifications 03.02.2022 "Order Save behaviour" release - make necessary changes
*/
public with sharing class OrderItemTriggerHelper {

	List<LogRegister> logs = new List<LogRegister>();
	List<Database.SaveResult> results;
	List<sObject> records;
	String process;
	String action;
	String sObjectType;
	String ParentField;

	List < Subscribed_Products__c > updateList = new List < Subscribed_Products__c > ();
	Map<ID, OrderItem> m;

	public void updateOrderSummary(Map<Id, List<OrderItem>> orderItemsMap) {
		//For each OP2, get Order2, update Enqix Order Summary String. AFTER INSERT
		// Fix: Accellor: Avoid fetching Order in loop
		Map<Id, Order> orderMap = new Map<Id, Order>([SELECT Id, Enqix_Order_Summary__c FROM Order WHERE Id IN :orderItemsMap.keySet()]);
		for (Order orderToUpdate : orderMap.values()) {
			// Fix: Accellor: Avoid fetching Order in loop
			// Order o = [Select Id, Enqix_Order_Summary__c from Order where Id =: ord];
			for (OrderItem item : orderItemsMap.get(orderToUpdate.Id)) {
				if (orderToUpdate.Enqix_Order_Summary__c == null) {
					orderToUpdate.Enqix_Order_Summary__c = '';
				}
				orderToUpdate.Enqix_Order_Summary__c += item.Quantity + ' x ' + item.Product_Name__c + '; ';
			}
			orderToUpdate.Enqix_Order_Summary__c = orderToUpdate.Enqix_Order_Summary__c.abbreviate(Order.Enqix_Order_Summary__c.getDescribe().getLength());
		}

		Database.SaveResult[] updateResults = Database.update(orderMap.values(), false);
		LogRegister.createLogsUpsert(updateResults, orderMap.values(), 'OrderItemTriggerHelper update ordToUpdateSummary', 'Update', 'Order', 'AccountId');
	}

	public void updateSubscribedProducts(Map<Id, OrderItem> listOrderItems, Map<Id,OrderItem> listOld, Boolean isInsert) {
		system.debug('Entrou um novo OrderItem para fazer update do quantity Ordered!');

		Set<Id> OrderIds = new Set<Id>();
		Set < Id > OrderItemsIds = new Set < Id > ();
		for (OrderItem p: listOrderItems.values()) {
			OrderItemsIds.add(p.Id);
			OrderIds.add(p.OrderId);
			//system.debug('Order Item #'+p.Id);
		}
		system.debug('list Order Items que foram modificados: ' + listOrderItems.size());

		List<Order> orders;
		List < OrderItem > orderItemsData;
		if(isInsert) {
			orders = [SELECT Id, AccountId FROM Order WHERE Id in :OrderIds AND Is_Salesforce__c = true];
			orderItemsData = [SELECT Id, OrderId, Quantity, Order.AccountId, Product2Id FROM OrderItem WHERE Id IN :OrderItemsIds AND Order.Is_Salesforce__c = true];
		}
		else {
			orders = [SELECT Id, AccountId FROM Order WHERE Id in :OrderIds];
			orderItemsData = [SELECT Id, OrderId, Quantity, Order.AccountId, Product2Id FROM OrderItem WHERE Id IN :OrderItemsIds];
		}

		//TODO 957

		system.debug('TAMANHO DOS ORDER ITEMS ###' + orders.size());
		system.debug('TAMANHO DOS ORDER ITEMS DATA ### ' + orderItemsData.size());


		Set<Id> productIds = new Set<Id>();
		Set<Id> accountIds = new Set<Id>();
		for(OrderItem o : listOrderItems.values()){
			productIds.add(o.Product2Id);
			//system.debug('Order Item Product Id #'+o.Product2Id);
			for(Order ord : orders){
				if(ord.Id == o.OrderId){
					accountIds.add(ord.AccountId);
					//system.debug('Order Item Account Id #'+ordem.AccountId);
				}
			}
		}
		system.debug('productIds --- ' +productIds);
		system.debug('accountIds --- ' +accountIds);
		//Account Id vem a zero, a lista vem vazia... DEBUG
		if(productIds.size() > 0 && accountIds.size() > 0){

		//jira 1947 --> Added condition to check if the subscribedProduct EndDate is still eligible to be applied, if not, dont update quantityOrdered
		//jira 1995 --> Added the EndDate = NULL verification
		List<Subscribed_Products__c> allsubs = [SELECT Id, Account__c, Product__c, quantityOrdered__c
												FROM Subscribed_Products__c WHERE Product__c in :productIds and Account__c in :accountIds and (EndDate__c >= TODAY OR EndDate__c = NULL)];
		system.debug('Tamanho dos Subs Products quando um OrderItem é inserido/alterado: '+allsubs.size());

		for (OrderItem o: orderItemsData) {
			//TODO 957
			for(Subscribed_Products__c sp : allsubs){
				if(sp.quantityOrdered__c == null )sp.quantityOrdered__c=0;
				//START Bruno 13-09
				if (sp.Product__c == o.Product2Id && sp.Account__c == o.Order.AccountId){
					//START JESSICA 18-10
					if(listOld == null){
						//Foi insert
						sp.quantityOrdered__c += o.Quantity;
						system.debug('quantity ordered nova = ' + sp.quantityOrdered__c);
					}else if(listOld.get(o.Id).Quantity == o.Quantity ){
						system.debug('quantity on the order did not change.');
						system.debug('valor antigo: '+listOld.get(o.Id).Quantity + ' valor novo: '+ o.Quantity);
					}else{
						sp.quantityOrdered__c += (o.Quantity - listOld.get(o.Id).Quantity);
						system.debug('quantity on the order changed, was updated ' );
						system.debug(o.Quantity +'-'+ listOld.get(o.Id).Quantity+' = '+ sp.quantityOrdered__c);
					}

					updateList.add(sp);


				}

			}
		}
			//END TODO 957
		}
		//system.debug('Check Quantity of Invoice Lines to Insert on continueInvoiceMontly: '+updateList.size());
		Set<Subscribed_Products__c> setNoDups = new Set<Subscribed_Products__c>(updateList);
		//system.debug('Check Quantity of Invoice Lines to Insert without duplicates: '+setNoDups.size());
		List<Subscribed_Products__c> updateListNoDups = new List<Subscribed_Products__c>(setNoDups);
		//update updateListNoDups;

		Database.SaveResult[] results_updateDB = Database.update(updateListNoDups,false);
		records = updateListNoDups;
		process = 'OrderItemTriggerHelper update updateListNoDups';
		action = 'Update';
		sObjectType = 'Subscribed_Products__c';
		ParentField = 'Account__c';

		LogRegister.createLogsUpsert(results_updateDB, records, process, action, sObjectType, ParentField);
	}

	//18-10 Jessica, when an Order Item is deleted, update the quantity Ordered on the subscribed product.
	public void subtractQuantityOrdered(Map<Id,OrderItem> erased){
		Set<Id> OrderIds = new Set<Id>();
		Set < Id > OrderItemsIds = new Set < Id > ();
		for (OrderItem p: erased.values()) {
			OrderItemsIds.add(p.Id);
			OrderIds.add(p.OrderId);
		}

		List<Order> ordens = [SELECT Id, AccountId FROM Order WHERE Id in :OrderIds];
		List < OrderItem > orderItemsData = [SELECT Id, OrderId, Quantity, Order.AccountId, Product2Id
											 FROM OrderItem WHERE Id IN :OrderItemsIds
											];

		Set<Id> productIds = new Set<Id>();
		Set<Id> accountIds = new Set<Id>();
		for(OrderItem o : erased.values()){
			productIds.add(o.Product2Id);
			//system.debug('Order Item Product Id #'+o.Product2Id);
			for(Order ord : ordens){
				if(ord.Id == o.OrderId){
					accountIds.add(ord.AccountId);
				}
			}
		}

		List<Subscribed_Products__c> allsubs = [SELECT Id, Account__c, Product__c, quantityOrdered__c
												FROM Subscribed_Products__c WHERE Product__c in :productIds  and Account__c in :accountIds];
		system.debug('Tamanho dos Subs Products quando um OrderItem é inserido/alterado: '+allsubs.size());

		for (OrderItem o: orderItemsData) {
			for(Subscribed_Products__c sp : allsubs){
				if(sp.quantityOrdered__c == null )sp.quantityOrdered__c=0;

				if (sp.Product__c == o.Product2Id && sp.Account__c == o.Order.AccountId){
					sp.quantityOrdered__c -= o.Quantity;
					system.debug('quantity ordered nova subtraida= ' + sp.quantityOrdered__c);
					updateList.add(sp);
				}
			}
		}
		Set<Subscribed_Products__c> setNoDups = new Set<Subscribed_Products__c>(updateList);
		List<Subscribed_Products__c> updateListNoDups = new List<Subscribed_Products__c>(setNoDups);
		//update updateListNoDups;

		Database.SaveResult[] results_updateDB = Database.update(updateListNoDups,false);
		records = updateListNoDups;
		process = 'OrderItemTriggerHelper update updateListNoDups';
		action = 'Update';
		sObjectType = 'Subscribed_Products__c';
		ParentField = 'Account__c';

		LogRegister.createLogsUpsert(results_updateDB, records, process, action, sObjectType, ParentField);
	}

	//Need to optimize this method when possible
	public void populateParterUnitPrice(List<OrderItem> lista) {
		system.debug('populate partner unit price');
		Set<Id> OrderItemIds = new Set<Id>();
		Set<Id> OrderIds = new Set<Id>();
		Set<Id> AccountIds = new Set<Id>();
		Set<Id> ProductItemIds = new Set<Id>();
		Set<Id> PricebookEntryIds = new Set<Id>();
		Map<Id, Id> pbeProduct2IdMap = new Map<Id, Id>();

		for(OrderItem o : lista){
			system.debug(o.OrderId + ' - '+ o.Product2Id);
			system.debug(o);
			OrderItemIds.add(o.Id);
			OrderIds.add(o.OrderId);
			//ProductItemIds.add(o.Product2Id);
			PricebookEntryIds.add(o.PricebookEntryId);
		}

		for (PricebookEntry pbe : [SELECT Id, Product2Id FROM PricebookEntry WHERE Id IN :PricebookEntryIds]) {
			//ProductItemIds.add(pbe.Product2Id);
			pbeProduct2IdMap.put(pbe.Id, pbe.Product2Id);
		}


		List<Order> orders = [SELECT Id, AccountId, Account.Partnership__c, Partner_Total_Amount__c from Order WHERE Id in :OrderIds];
		for(Order o : orders){
			AccountIds.add(o.Account.Partnership__c);
		}
		system.debug('Partnerships encontrados: ' + AccountIds.size() + ' ' + AccountIds);
		system.debug('OrderItemIds.size() = '+OrderItemIds.size());
		system.debug('lista.size() = '+ lista.size());
		system.debug('AccountIds = ' + AccountIds);
		system.debug('ProductItemIds = ' + pbeProduct2IdMap);

		Id partnerdiscount_RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();
		List<Account_Discount__c> discounts = new List <Account_Discount__c>();

		discounts = [SELECT Id, Product__c, Account__c, RecordTypeId, BID_Price__c, BID_Rebate__c, RecordType.DeveloperName, Product_Discount__c, EnqixBIDId__c
												   from Account_Discount__c where Account__c in :AccountIds AND Product__c in :pbeProduct2IdMap.values()
												   AND RecordType.DeveloperName = 'PartnerDiscount' AND DiscountSupStartDate__c <= TODAY AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)
												  ];
		/*if(!test.isRunningTest()){
			discounts = [SELECT Id, Product__c, Account__c, RecordTypeId, BID_Price__c, BID_Rebate__c, RecordType.DeveloperName, Product_Discount__c, EnqixBIDId__c
												   from Account_Discount__c where Account__c in :AccountIds AND Product__c in :pbeProduct2IdMap.values()
												   AND RecordType.DeveloperName = 'PartnerDiscount' AND DiscountSupStartDate__c <= TODAY AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)
												  ];
		}else{
		   discounts = [SELECT Id, Product__c, Account__c, RecordTypeId, BID_Price__c, BID_Rebate__c,Product_Discount__c RecordType.DeveloperName from Account_Discount__c];
		} */

		system.debug('Account Discounts encontradas : ' + discounts.size() + ' ' + discounts);

		/* Changes made on 05/11/2018  - Apex CPU Time Limit exceeded. Maybe because there were too many for loops inside for loops. it caused by the inner for, when looping the lista from orderitems. */
		Map<OrderItem, Id> partnersFromOrderItems = new Map<OrderItem, Id>();
		//Map<OrderItem, Order> getOrderFromOrderItem = new Map<OrderItem, Order>();

		for(Order o : orders){
			for(OrderItem oo : lista){
				if(oo.OrderId == o.Id ){
					//getOrderFromOrderItem.put(oo, o);
					system.debug('> Order e OrderItem . Account Partnership: '+ o.Account.Partnership__c);
					if(o.Account.Partnership__c != null){
						partnersFromOrderItems.put(oo, o.Account.Partnership__c);
					}
				}
			}
		}

		for(Account_Discount__c discount : discounts){
			Id product2Id;
			system.debug('> This is the Discount of Type Partner: ' + discount);
			if(discount.BID_Price__c != null && discount.BID_Price__c != 0){
				system.debug('> > BID PRICE. ');
				for(OrderItem orderitem : lista){
					product2Id = pbeProduct2IdMap.get(orderitem.PricebookEntryId);
					if(partnersFromOrderItems.get(orderitem) == discount.Account__c && product2Id == discount.Product__c){
						orderitem.Partner_Unit_Price__c = discount.BID_Price__c;
						orderitem.EnqixBIDId__c = discount.EnqixBIDId__c;
						system.debug('Product that has Discount: ' + product2Id + ' | Added to Partner Unit Price! =>  '+ orderitem.Partner_Unit_Price__c);
					}
				}
			}

			if(discount.BID_Rebate__c != null && discount.BID_Rebate__c != 0 ){
				system.debug('> > BID REBATE. ');
				for(OrderItem orderitem : lista){
					product2Id = pbeProduct2IdMap.get(orderitem.PricebookEntryId);
					if(partnersFromOrderItems.get(orderitem) == discount.Account__c && product2Id == discount.Product__c)
						orderitem.Partner_Unit_Price__c = discount.BID_Rebate__c * -1;
					system.debug('Product that has Discount: ' + product2Id + ' | Added to Partner Unit Price! =>  '+ orderitem.Partner_Unit_Price__c);

				}
			}
		}
	}

	public void populatePartnerTotalAmount(List<OrderItem> lista, Boolean isInsert) {
		List<Order> toUpdateOrder = new List<Order>();
		Set<Id> OrderIds = new Set<Id>();
		for(OrderItem o : lista){
			if (o.OrderId != null) {
				OrderIds.add(o.OrderId);
			}
		}
		if(!OrderIds.isEmpty()) {
			Map<Id, Order> ordersMap = new Map<Id, Order>([Select Id, AccountId, Partner_Total_Amount__c, Created_Later__c, (SELECT Partner_Unit_Price__c, Partner_Total_Price__c, OrderId from OrderItems) from Order where Id IN: OrderIds]);
			for(OrderItem oi: lista) {
				if(oi.OrderId != null) {
					Order o = ordersMap.get(oi.OrderId);
					o.Partner_Total_Amount__c = 0;
					if (oi.Partner_Unit_Price__c == null) continue;
					o.Partner_Total_Amount__c += oi.Partner_Total_Price__c;
					// 1227
					if (o.Status == 'Delivered' && isInsert && !o.Created_Later__c) {
						o.Created_Later__c = true;
					}
					system.debug('Order . Partner Total Amount nao é nulo, incrementa valor! ' + o.Partner_Total_Amount__c + ' + ' + oi.Partner_Total_Price__c);
					toUpdateOrder.add(o);
				}
			}
		}

		if(toUpdateOrder.size()>0){
			Set<Order> setOrders = new Set<Order>(toUpdateOrder);
			system.debug('Check Quantity of Orders to Insert without duplicates: '+setOrders.size());
			List<Order> listToInsertOrders = new List<Order>(setOrders);

			Database.SaveResult[] results_updateOD = Database.update(listToInsertOrders,false);
			records = listToInsertOrders;
			process = 'OrderItemTriggerHelper update listToInsertOrders';
			action = 'Update';
			sObjectType = 'Order';
			ParentField = 'AccountId';

			LogRegister.createLogsUpsert(results_updateOD, records, process, action, sObjectType, ParentField);
		}
	}

	public void populateDiscountField(List<OrderItem> orderProds) {
		Set < Id > partnerIds = new Set < Id > ();
		Set < Id > accountIds = new Set < Id > ();
		Set < Id > partnerProductsIds = new Set < Id > ();
		Set < Id > accountProductsIds = new Set < Id > ();
		Set < Id > orderIds = new Set < Id > ();
		Id order;

		Map <Id,List<OrderItem>> orderWithOrderLines = new Map <Id,List<OrderItem>>();

		for(OrderItem  op : orderProds){
			if (orderWithOrderLines.containsKey(op.OrderId)){
				orderWithOrderLines.get(op.OrderId).add(op);
			}else{
				orderWithOrderLines.put(op.OrderId, new  List <OrderItem> {op});
			}
		}

		for(Order ord: [Select Id, Account.ParentId, Account.Partnership__c from Order where ID =:orderWithOrderLines.keySet()]){
			order = ord.Id;
			for(OrderItem op: orderWithOrderLines.get(order)){
				if(op.Product2Id != null && op.Discount_to_Apply__c == 'Account') {
					accountProductsIds.add(op.Product2Id);
					accountIds.add(ord.Account.ParentId);
				} else if (op.Product2Id != null && op.Discount_to_Apply__c == 'Partner') {
					partnerProductsIds.add(op.Product2Id);
					partnerIds.add(ord.Account.Partnership__c);
				}
			}
		}

		system.debug('partnerIds --> '+partnerIds);
		system.debug('accountIds --> '+accountIds);


		Map < String, Account_Discount__c > adPartnerMap = new Map < String, Account_Discount__c > ();
		Map < String, Account_Discount__c > adAccountMap = new Map < String, Account_Discount__c > ();

		for (Account_Discount__c ad: [SELECT Id, Account__c, RecordType.DeveloperName, Product__c, Product_Discount__c, BID_Price__c
									  FROM Account_Discount__c WHERE Account__c in: partnerIds AND Product__c in: partnerProductsIds AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)
									 ]) {
										 string key = ad.Account__c + '-' + ad.Product__c;
										 adPartnerMap.put(key, ad);
									 }
		for (Account_Discount__c ad: [SELECT Id, Account__c, RecordType.DeveloperName, Product__c, Product_Discount__c
									  FROM Account_Discount__c WHERE Account__c in: accountIds AND Product__c in: accountProductsIds AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)
									 ]) {
										 string key = ad.Account__c + '-' + ad.Product__c;
										 adAccountMap.put(key, ad);
									 }

		system.debug('adPartnerMap size: ' + adPartnerMap.keySet().size() + ' Conteudo: \n' + adPartnerMap.values());
		system.debug('adAccountMap size: ' + adAccountMap.keySet().size() + ' Conteudo: \n' + adAccountMap.values());

		for(Order ord: [Select Id, Account.ParentId, Account.Partnership__c from Order where ID =:orderWithOrderLines.keySet()]){
			order = ord.Id;
			for(OrderItem op: orderWithOrderLines.get(order)){
				string cwKeyPartner = ord.Account.Partnership__c + '-' + op.Product2Id;
				string cwKeyAccount = ord.Account.ParentId + '-' + op.Product2Id;
				if (adPartnerMap.containsKey(cwKeyPartner) && op.Discount_to_Apply__c == 'Partner') {
					Account_Discount__c ad = adPartnerMap.get(cwKeyPartner);
					if (ad.Product_Discount__c == null){
						ad.Product_Discount__c = 0;
					}
					if (ad.BID_Price__c == null){
						ad.BID_Price__c = 0;
					}
					op.Account_Discount__c = ad.Id;
					op.Partner_Discount__c = ad.Product_Discount__c + ad.BID_Price__c;
				}
				else if (adAccountMap.containsKey(cwKeyAccount) && op.Discount_to_Apply__c == 'Account') {
					Account_Discount__c ad = adAccountMap.get(cwKeyAccount);
					op.Account_Discount__c = ad.Id;
					op.Discount__c = ad.Product_Discount__c;
				}
			}
		}
		populateTotalDiscount(orderProds);
	}

	public void populatePricebookEntryId(List<OrderItem> orderProds, set<Id> productId, set<Id> pricebookId) {
		Map<String, PricebookEntry> pricebookEntry = new Map<String, PricebookEntry>();
		List<PricebookEntry> pricebooks = [SELECT Id, Pricebook2Id, Product2Id, UnitPrice FROM PricebookEntry WHERE Pricebook2Id =:pricebookId and Product2Id =:productId];
		Id pbE;
		decimal unitPrice;

		for (PricebookEntry pE : pricebooks){
			system.debug('pE --> '+pE);
			pricebookEntry.put( String.valueof(pE.Pricebook2Id) + String.valueOf(pE.Product2Id) , pE);
		}

		for (OrderItem oi : orderProds){
			String pricebook_product = String.valueof(oi.Price_Book__c) + String.valueof(oi.Product2Id);
			if (pricebookEntry.containsKey(pricebook_product)){
				pbE = pricebookEntry.get(pricebook_product).Id;
				System.debug('pricebook_productUnitPrice -- ' + pricebookEntry.get(pricebook_product).UnitPrice);
				System.debug('priceBookOrder' + oi.OrderId);
				System.debug('priceBookList_Price__c' + oi.ListPrice__c);
				unitPrice = pricebookEntry.get(pricebook_product).UnitPrice;
				if (oi.ListPrice__c == null){
					oi.ListPrice__c = unitPrice;
				}
			}
			oi.PricebookEntryId = pbe;
			system.debug('oi.PricebookEntryId --> '+oi.PricebookEntryId);
		}
		populateTotalDiscount(orderProds);
	}

	public void populateTotalDiscount(List<OrderItem> orderProds) {
		decimal priceWithDiscount = 0;
		for(OrderItem oi : orderProds){
			system.debug('Parent.Overriding_Account_discount__c --> ' +oi.Overriding_Account_discount__c);
			system.debug('Parent.Direct_Debit_Discount__c --> ' +oi.Direct_Debit_Discount__c);
			system.debug('ListPrice__c --> ' +oi.ListPrice__c);
			system.debug('ListPrice --> ' +oi.ListPrice);
			system.debug('PricebookEntryId --> ' +oi.PricebookEntryId);
			system.debug('Discount__c --> ' +oi.Discount__c);
			system.debug('order --' + oi.OrderId);
			//If the Order being created is not a 'credit note' order
			if (oi.Credit_Note_line__c == False){
				if (oi.ListPrice__c == null && oi.ListPrice != null){
					oi.ListPrice__c = oi.ListPrice;
				}
				if (oi.Discount_to_Apply__c == 'Account') {
					if (oi.Discount__c != null && oi.ListPrice__c != null){
						priceWithDiscount = oi.ListPrice__c - oi.Discount__c;
						system.debug('priceWithDiscount --> '+priceWithDiscount);
					}
					system.debug('Discount__c --> '+oi.Discount__c);
					//Has Acc discount and overriding discount and dd discount
					if ((oi.Discount__c > 0 || oi.Discount__c < 0) && oi.Direct_Debit_Discount__c > 0 && oi.Overriding_Account_discount__c > 0) {
						oi.Total_Discount__c = oi.Discount__c + (priceWithDiscount * (oi.Direct_Debit_Discount__c / 100)) + (priceWithDiscount * (oi.Overriding_Account_discount__c / 100));
						system.debug('Total_Discount__c --> '+oi.Total_Discount__c);
						//Has Acc discount and Overriding discount
					} else if ((oi.Discount__c > 0 || oi.Discount__c < 0) && oi.Overriding_Account_discount__c > 0 && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0)){
						oi.Total_Discount__c = oi.Discount__c + (priceWithDiscount * (oi.Overriding_Account_discount__c / 100));
						//Has Acc discount and dd discount
					} else if ((oi.Discount__c > 0 || oi.Discount__c < 0) && oi.Direct_Debit_Discount__c > 0 && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0)){
						oi.Total_Discount__c = oi.Discount__c + (priceWithDiscount * (oi.Direct_Debit_Discount__c / 100));
						//Has Acc discount
					} else if ((oi.Discount__c > 0 || oi.Discount__c < 0) && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0) && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0)){
						oi.Total_Discount__c = oi.Discount__c;
						//Has overriding discount and DD discount
					} else if (oi.Overriding_Account_discount__c > 0 && oi.Direct_Debit_Discount__c > 0 && (oi.Discount__c == null || oi.Discount__c == 0)){
						oi.Total_Discount__c = (oi.ListPrice__c * (oi.Overriding_Account_discount__c / 100)) + (oi.ListPrice__c * (oi.Direct_Debit_Discount__c / 100));
						//Has overriding discount
					} else if (oi.Overriding_Account_discount__c > 0 && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0) && (oi.Discount__c == null || oi.Discount__c == 0)) {
						oi.Total_Discount__c = oi.ListPrice__c * (oi.Overriding_Account_discount__c / 100);
						//Has DD discount
					} else if (oi.Direct_Debit_Discount__c > 0 && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0) && (oi.Discount__c == null || oi.Discount__c == 0)) {
						oi.Total_Discount__c = oi.ListPrice__c * (oi.Direct_Debit_Discount__c / 100);
					} else {
						oi.Total_Discount__c = 0;
					}
				} else if (oi.Discount_to_Apply__c == 'Partner') {
					if (oi.Partner_Discount__c != null){
						priceWithDiscount = oi.ListPrice__c - oi.Partner_Discount__c;
					}
					//Has Partner discount and overriding discount and dd discount
					if (oi.Partner_Discount__c > 0 && oi.Direct_Debit_Discount__c > 0 && oi.Overriding_Account_discount__c > 0) {
						oi.Total_Discount__c = oi.Partner_Discount__c + (priceWithDiscount * (oi.Direct_Debit_Discount__c / 100)) + (priceWithDiscount * (oi.Overriding_Account_discount__c / 100));
						//Has Partner discount and Overriding discount
					} else if (oi.Partner_Discount__c > 0 && oi.Overriding_Account_discount__c > 0 && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0)){
						oi.Total_Discount__c = oi.Partner_Discount__c + (priceWithDiscount * (oi.Overriding_Account_discount__c / 100));
						//Has Partner discount and dd discount
					} else if (oi.Partner_Discount__c > 0 && oi.Direct_Debit_Discount__c > 0 && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0)){
						oi.Total_Discount__c = oi.Partner_Discount__c + (priceWithDiscount * (oi.Direct_Debit_Discount__c / 100));
						//Has Partner discount
					} else if (oi.Partner_Discount__c > 0 && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0) && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0)){
						oi.Total_Discount__c = oi.Partner_Discount__c;
						//Has overriding discount and DD discount
					} else if (oi.Overriding_Account_discount__c > 0 && oi.Direct_Debit_Discount__c > 0 && (oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0)){
						oi.Total_Discount__c = (oi.ListPrice__c * (oi.Overriding_Account_discount__c / 100)) + (oi.ListPrice__c * (oi.Direct_Debit_Discount__c / 100));
						//Has overriding discount
					} else if (oi.Overriding_Account_discount__c > 0 && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0) && (oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0)) {
						oi.Total_Discount__c = oi.ListPrice__c * (oi.Overriding_Account_discount__c / 100);
						//Has DD discount
					} else if (oi.Direct_Debit_Discount__c > 0 && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0) && (oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0)) {
						oi.Total_Discount__c = oi.ListPrice__c * (oi.Direct_Debit_Discount__c / 100);
					} else {
						oi.Total_Discount__c = 0;
					}
				} else if (oi.Discount_to_Apply__c == null) {
					//Has overriding discount and DD discount
					if (oi.Overriding_Account_discount__c > 0 && oi.Direct_Debit_Discount__c > 0 && (oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0)){
						oi.Total_Discount__c = (oi.ListPrice__c * (oi.Overriding_Account_discount__c / 100)) + (oi.ListPrice__c * (oi.Direct_Debit_Discount__c / 100));
						//Has overriding discount
					} else if (oi.Overriding_Account_discount__c > 0 && (oi.Direct_Debit_Discount__c == null || oi.Direct_Debit_Discount__c == 0) && (oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0)) {
						oi.Total_Discount__c = oi.ListPrice__c * (oi.Overriding_Account_discount__c / 100);
						//Has DD discount
					} else if (oi.Direct_Debit_Discount__c > 0 && (oi.Overriding_Account_discount__c == null || oi.Overriding_Account_discount__c == 0) && (oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0)) {
						oi.Total_Discount__c = oi.ListPrice__c * (oi.Direct_Debit_Discount__c / 100);
					} else {
						oi.Total_Discount__c = 0;
					}
				}
			}
		}
		populatePriceFields(orderProds);
	}

	public void populatePriceFields(List<OrderItem> orderProds) {
		for(OrderItem oi : orderProds){
			if (oi.PriceBookEntryId == null){
				oi.addError('No PricebookEntry was found related to the product being used on this OrderProduct --> '+oi.id);
			}else{
				if (oi.UnitPrice == null){
					if (oi.ListPrice__c != null) {
						oi.UnitPrice = oi.ListPrice__c.setscale(2);
					} else if (oi.ListPrice != null && oi.ListPrice__c == null){
						oi.UnitPrice = oi.ListPrice;
					}
				}

				//When adding a new order product to an Order already created and has a discount to be applied
				if (oi.UnitPrice != null && oi.Total_Discount__c != null && (oi.Total_Discount__c > 0 || oi.Total_Discount__c < 0)){
					if (oi.ListPrice__c - oi.Total_Discount__c >= 0){
						oi.UnitPrice = oi.ListPrice__c - oi.Total_Discount__c.setscale(2);
					} else {
						oi.UnitPrice = oi.ListPrice__c.setscale(2);
					}
				}

				if(oi.UnitPrice != null){
					oi.Net_Price__c = oi.UnitPrice.setscale(2) * oi.Quantity;
				}

				if(oi.Supplier_Unit_Price__c != null){
					oi.Supplier_total__c = oi.Supplier_Unit_Price__c * oi.Quantity;
				}
				system.debug('unit price --> '+oi.UnitPrice);
			}
		}
	}


	public void populateSupplierFields(List<OrderItem> orderProds, boolean isUpdate) {
		set<Id> supplierIds = new set<Id>();
		set<Id> ProductIds = new set<Id>();
		// Fix: Accellor: Avoid fetching Order in loop
		Set<Id> orderIds = new Set<Id>();
		for(OrderItem oi : orderProds){
			// Fix: Accellor: Avoid fetching Order in loop
			orderIds.add(oi.OrderId);
			system.debug('oi id -->'+oi.id);
			if(oi.Is_supplier_Order_Prod__c == true){
				if(oi.Post_code_for_supplier__c == null && oi.Order.ShippingPostcode__c != null){
					oi.Post_code_for_supplier__c = oi.Order.ShippingPostcode__c;
				}
				if(oi.shipping_address_for_supplier__c == null && oi.Order.ShippingStreet != null){
					oi.shipping_address_for_supplier__c = oi.Order.ShippingStreet;
				}
				if(oi.supplier_email_text__c == null && oi.Supplier__r.email__c != null){
					oi.supplier_email_text__c = oi.Supplier__r.email__c;
				}
				if(oi.Supplier_location_name__c == null && oi.Order.Account.Name != null){
					oi.Supplier_location_name__c = oi.Order.Account.Name;
				}
			}
			if(oi.Supplier__c != null){
				supplierIds.add(oi.Supplier__c);
			}
			if(oi.Product2Id != null){
				ProductIds.add(oi.Product2Id);
			}
		}
		//To populate Supplier Unit Price
		List<Supplier_Product__c> supplierProducts = [SELECT Id, Supplier__c, Supplier_Price__c,Product__c FROM Supplier_Product__c WHERE Product__c IN :ProductIds AND Supplier__c IN :supplierIds AND (Start_Date__c <= TODAY OR Start_Date__c = null) AND (End_Date__c >= Today OR End_Date__c = null)];

		// Fix: Accellor: Avoid fetching Order in loop
		Map<Id, Order> orderMap = new Map<Id, Order>([SELECT RecurringId__c, RecurringId__r.Supplier_Unit_Price__c FROM Order WHERE Id IN :orderIds]);
		for(OrderItem op : orderProds){
			if(op.Supplier__c != null){
				// Fix: Accellor: Avoid fetching Order in loop
				Order o = orderMap.get(op.OrderId);
				// Order o = [Select RecurringId__c, RecurringId__r.Supplier_Unit_Price__c from Order where Id =: op.OrderId];
				if (o.RecurringId__r.Supplier_Unit_Price__c != null){
					op.Supplier_Unit_Price__c = o.RecurringId__r.Supplier_Unit_Price__c;
				} else {
					for(Supplier_Product__c sp: supplierProducts){
						if(op.Supplier__c == sp.Supplier__c && op.Product2Id == sp.Product__c && op.Supplier_Unit_Price__c == null && isUpdate == false){
							op.Supplier_Unit_Price__c = sp.Supplier_Price__c;
							break;
						}
					}
				}
			}
		}
	}

	//Jira 1653 start
	public static void orderProductsValidation(set < Id > orderIds, List<OrderItem> newOrderProducts) {
		System.debug('Parameter Order IDs: ' + orderIds);
		System.debug('Parameter newOrdProd Map: ' + newOrderProducts);

		//This map relates the OrderId with the new Order products
		Map <Id, List<OrderItem>> orderToOrderProduct = new Map <Id, List<OrderItem>>();
		//This map allows the process to identify if the same order have both positive and negative order products. [0] for positives and [1] for negatives
		Map <Id, Boolean[]> orderProductsPositiveNegative = new Map <Id, Boolean[]>();

		//Iterate over new Order Products
		for (OrderItem orderProduct :newOrderProducts)
		{
			organizeMaps(orderProduct, orderToOrderProduct, orderProductsPositiveNegative, true);
		}

		List<OrderItem> existingOrderProducts = [Select Id, OrderId, Quantity from OrderItem where OrderId =:orderIds];
		//Iterate over Existing Order Products
		for (OrderItem orderProduct :existingOrderProducts)
		{
			organizeMaps(orderProduct, orderToOrderProduct, orderProductsPositiveNegative, false);
		}
		system.debug('OrdProd Map:' + orderToOrderProduct);
		system.debug('posNeg Map:' + orderProductsPositiveNegative);
		//Validate if ther ise negative and positive orders in the same order
		for (Id OderID: orderProductsPositiveNegative.keySet()) {
			if( orderProductsPositiveNegative.get(OderID)[0] == true && orderProductsPositiveNegative.get(OderID)[1] == true)
				throwErrorsForOrderProducts(orderToOrderProduct.get(OderID), newOrderProducts);
		}
	}

	private static void organizeMaps(OrderItem orderProduct, Map <Id, List<OrderItem>> orderToOrderProduct, Map <Id, Boolean[]>  orderProductsPositiveNegative, Boolean isNew)
	{
		Boolean[] opSignals;
		List<OrderItem> relatedOrderProducts;
		//verify if a related order ID already exists in the Map
		if(orderProductsPositiveNegative.containskey(orderProduct.orderId)){
			opSignals = orderProductsPositiveNegative.get(orderProduct.orderId);
		}else{
			opSignals = new Boolean[2];
		}
		//verify if a related order products already exists in the Map
		if(orderToOrderProduct.containskey(orderProduct.orderId)){
			relatedOrderProducts = orderToOrderProduct.get(orderProduct.orderId);
		}else{
			relatedOrderProducts = new List<OrderItem>();
		}

		//Attribute the right values to the boolean array
		if (orderProduct.Quantity > 0 && opSignals[0] != true)
		{
			opSignals[0] = true;
		}
		else if (orderProduct.Quantity < 0 && opSignals[1] != true)
		{
			opSignals[1] = true;
		}

		//store information on maps
		relatedOrderProducts.add(orderProduct);//add the orderProduct to be able to fecth it later if necessary
		orderToOrderProduct.put(orderProduct.orderId, relatedOrderProducts);
		orderProductsPositiveNegative.put(orderProduct.orderId, opSignals);
	}


	private static void throwErrorsForOrderProducts(List<OrderItem> orderProducts,  List<OrderItem> newOrderProducts )
	{
		for(OrderItem orderProduct :orderProducts)
		{
			for(OrderItem neworderProduct :newOrderProducts)
				if(orderProduct.ID == neworderProduct.Id)
					neworderProduct.addError('Both positive and negative quantity order products on same Order is not allowed.');
		}
	}
	//Jira 1653 end
}