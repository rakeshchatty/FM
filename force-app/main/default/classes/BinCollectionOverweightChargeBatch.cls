public without sharing class BinCollectionOverweightChargeBatch implements Database.Batchable<sObject> {

	private Map<Id, Order> orderIdToChargeOrderMap = new Map<Id, Order>();
	private Map<Id, List<OrderItem>> orderIdToOrderItemsMap = new Map<Id, List<OrderItem>>();

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		List<OrderItem> orderItems = [SELECT Order.AccountId FROM OrderItem
			WHERE Order.Account.IsOverweightChargesEnabled__c = true AND Order.IsBinCollection__c = true
			AND Collection_Waypoint__r.Type__c != 'Missed' AND OverweightToInvoice__c > 0
			AND Product2.OverweightChargeProduct__c != null
			AND (DAY_ONLY(CreatedDate) >= LAST_N_DAYS:7 OR CreatedDate = THIS_MONTH)];

		Set<Id> accountIds = new Set<Id>();
		for (OrderItem orderItem : orderItems) {
			accountIds.add(orderItem.Order.AccountId);
		}
		return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN :accountIds]);
	}

	public void execute(Database.BatchableContext bc, List<Account> scope) {
		List<OrderItem> orderItems = [SELECT OrderId, Overweight__c, OverweightToInvoice__c, Product2.OverweightChargeProduct__c, Order.AccountId, Order.Account.Price_Book__c, Order.Delivery_Date__c, Order.Supplier__c, Order.Supplier__r.Name
			FROM OrderItem
			WHERE Order.Account.IsOverweightChargesEnabled__c = true AND Order.IsBinCollection__c = true
			AND Collection_Waypoint__r.Type__c != 'Missed' AND OverweightToInvoice__c > 0
			AND Product2.OverweightChargeProduct__c != null
			AND (DAY_ONLY(CreatedDate) >= LAST_N_DAYS:7 OR CreatedDate = THIS_MONTH)
			AND Order.AccountId IN :scope ORDER BY OrderId];

		loadOrderIdToChargeOrderMap(orderItems);

		Database.SaveResult[] results = Database.insert(orderIdToChargeOrderMap.values(), false);
		LogRegister.createLogsUpsert(results, orderIdToChargeOrderMap.values(), 'Overweight Charge Orders', 'Insert', 'Order', 'AccountId');

		List<OrderItem> chargeProducts = createChargeProducts();

		results = Database.insert(chargeProducts, false);
		LogRegister.createLogsUpsert(results, chargeProducts, 'Overweight Charge Order Products', 'Insert', 'OrderItem', 'OrderId');

		results = Database.update(orderIdToChargeOrderMap.values(), false);	// Status to Delivered
		LogRegister.createLogsUpsert(results, orderIdToChargeOrderMap.values(), 'Overweight Charge Order status to Delivered', 'Update', 'Order', 'AccountId');

		results = Database.update(orderItems, false);	// OverweightInvoiced field
		LogRegister.createLogsUpsert(results, orderItems, 'Overweight Bin Collection Orders', 'Update', 'OrderItem', 'OrderId');
	}

	public void finish(Database.BatchableContext bc) {}

	private void loadOrderIdToChargeOrderMap(List<OrderItem> orderItems) {
		for (OrderItem orderItem : orderItems) {
			if (!orderIdToChargeOrderMap.containsKey(orderItem.OrderId)) {
				orderIdToChargeOrderMap.put(orderItem.OrderId, createChargeOrder(orderItem.order));
				orderIdToOrderItemsMap.put(orderItem.OrderId, new List<OrderItem>());
			}

			orderIdToOrderItemsMap.get(orderItem.OrderId).add(orderItem);

			orderItem.OverweightInvoiced__c = orderItem.Overweight__c;
		}
	}

	private Order createChargeOrder(Order order) {
		Order chargeOrder = OrderUtil.createOrder(Order.AccountId, order.Supplier__r, order.Delivery_date__c);
		chargeOrder.Pricebook2Id = order.Account.Price_Book__c;
		chargeOrder.CollectionOrder__c = order.Id;
		chargeOrder.Delivery_date__c = order.Delivery_date__c;
		return chargeOrder;
	}

	private List<OrderItem> createChargeProducts() {
		List<OrderItem> chargeProducts = new List<OrderItem>();
		Order chargeOrder;
		for (Id orderId : orderIdToOrderItemsMap.keySet()) {
			chargeOrder = orderIdToChargeOrderMap.get(orderId);
			chargeOrder.Status = 'Delivered';
			chargeProducts.addAll(createChargeProducts(chargeOrder, orderIdToOrderItemsMap.get(orderId)));
		}

		return chargeProducts;
	}

	private List<OrderItem> createChargeProducts(Order chargeOrder, List<OrderItem> orderItems) {
		Map<Id, Decimal> chargeProductToOverweight = new Map<Id, Decimal>();
		Decimal overweight;
		for (OrderItem orderItem : orderItems) {
			overweight = chargeProductToOverweight.get(orderItem.Product2.OverweightChargeProduct__c);
			overweight = overweight != null ? overweight + orderItem.OverweightToInvoice__c : orderItem.OverweightToInvoice__c;
			chargeProductToOverweight.put(orderItem.Product2.OverweightChargeProduct__c, overweight);
		}
		
		List<OrderItem> chargeProducts = new List<OrderItem>();
		for (Id chargeProductId : chargeProductToOverweight.keySet()) {
			chargeProducts.add(OrderUtil.createOrderItem(chargeOrder.Id, chargeProductId, chargeProductToOverweight.get(chargeProductId), chargeOrder.Pricebook2Id, null, null, null, chargeOrder.Supplier__c));
		}

		return chargeProducts;
	}
}