public without sharing class BinCollectionToOrderBatch implements Database.Batchable<sObject> {

	private static final String KEY_FORMAT = '{0}-{1}-{2}-{3}';
	private Map<String, List<Collection_Waypoints__c>> binCollectionWaypointsByOrder = new Map<String, List<Collection_Waypoints__c>>();

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN
			(SELECT Location__c FROM Collection_Waypoints__c WHERE Location__r.Parent.IsBinCollectionAdvanceInvoiced__c = false AND
				Is_bin_collection__c = true AND Order_Created__c = false AND Location__r.Enqix_Dead_Live__c = 'Live' AND Type__c != 'Missed' AND (Daily_Dispatch__r.EndTime__c = TODAY OR Daily_Dispatch__r.EndTime__c = YESTERDAY))]);
	}

	public void execute(Database.BatchableContext batchContext, List<Account> locations) {
		List<Collection_Waypoints__c> binCollectionWaypoints = [SELECT Collection_Quantity__c, Daily_Dispatch__r.CreatedDate, Location__c, Location__r.Price_Book__c, Supplier__c, Supplier__r.Name, Supplier_Product__r.Product__c,
				Manual_Price__c, Discount_Type__c, Account_Discount__c, Account_Discount__r.BID_Price__c, Account_Discount__r.Product_Discount__c, Collection_Schedule__r.Po_Number__c
			FROM Collection_Waypoints__c
			WHERE Location__c IN :locations AND
				Is_bin_collection__c = true AND Order_Created__c = false AND Location__r.Enqix_Dead_Live__c = 'Live' AND Type__c != 'Missed' AND (Daily_Dispatch__r.EndTime__c = TODAY OR Daily_Dispatch__r.EndTime__c = YESTERDAY)
			ORDER BY Location__c];

		for (Collection_Waypoints__c collectionWaypoint : binCollectionWaypoints) {
			String orderKey = getUniqueOrderKey(collectionWaypoint);
			if (!binCollectionWaypointsByOrder.containsKey(orderKey)) {
				binCollectionWaypointsByOrder.put(orderKey, new List<Collection_Waypoints__c>());
			}
			binCollectionWaypointsByOrder.get(orderKey).add(collectionWaypoint);
		}

		insertOrderItems(insertOrders());
	}

	private String getUniqueOrderKey(Collection_Waypoints__c collectionWaypoint) {
		String poNumber = collectionWaypoint.Collection_Schedule__r.Po_Number__c;
		return String.format(KEY_FORMAT, new Object[]{collectionWaypoint.Daily_Dispatch__r.CreatedDate.date().format(), collectionWaypoint.Location__c, collectionWaypoint.Supplier__c, String.isNotBlank(poNumber) ? poNumber : null});
	}

	private String getUniqueOrderKey(Order order) {
		return String.format(KEY_FORMAT, new Object[]{order.EffectiveDate.format(), order.AccountId, order.Supplier__c, String.isNotBlank(order.Po_Number__c) ? order.Po_Number__c : null});
	}

	private List<Order> insertOrders() {
		List<Order> orders = new List<Order>();

		for (String orderKey : binCollectionWaypointsByOrder.keySet()) {
            orders.add(OrderUtil.createOrder(binCollectionWaypointsByOrder.get(orderKey)[0]));
		}

		Database.SaveResult[] results = Database.insert(orders, false);
		LogRegister.createLogsUpsert(results, orders, 'Bin Collection Orders', 'Insert', 'Order', 'AccountId');

		return orders;
	}

	private List<OrderItem> insertOrderItems(List<Order> orders) {
		List<OrderItem> orderItems = new List<OrderItem>();

		for (Order order : orders) {
			for (Collection_Waypoints__c collectionWaypoint : binCollectionWaypointsByOrder.get(getUniqueOrderKey(order))) {
				orderItems.add(OrderUtil.createOrderItem(order, collectionWaypoint));
			}
		}

		Database.SaveResult[] results1 = Database.insert(orderItems, false);
		LogRegister.createLogsUpsert(results1, orderItems, 'OrderItems added to newly created Bin Collection Orders', 'Insert', 'OrderItem', 'OrderId');

        OrderUtil.setBinOrderAsConfirmed(orders);
		Database.SaveResult[] results2 = Database.update(orders, false);
		LogRegister.createLogsUpsert(results2, orders, 'Set Bin Collection Orders to Confirmed status', 'Update', 'Order', 'AccountId');

		markOrderCreated(orderItems);

		return orderItems;
	}

	private void markOrderCreated(List<OrderItem> orderItems) {
		List<Collection_Waypoints__c> binCollectionWaypoints = new List<Collection_Waypoints__c>();

		for (Collection_Waypoints__c collectionWaypoint : [SELECT Id, Location__c FROM Collection_Waypoints__c WHERE ID IN (SELECT Collection_Waypoint__c FROM OrderItem WHERE Id IN :orderItems)]) {
			collectionWaypoint.Order_Created__c = true;
			binCollectionWaypoints.add(collectionWaypoint);
		}

		if (!binCollectionWaypoints.isEmpty()) {
			Database.SaveResult[] results = Database.update(binCollectionWaypoints, false);
			LogRegister.createLogsUpsert(results, binCollectionWaypoints, 'Set Bin Collection Waypoints as Order Created', 'Update', 'Collection_Waypoints__c', 'Location__c');
		}
	}

	public void finish(Database.BatchableContext batchContext) {
		Database.executeBatch(new BinWeightToWeightBatch(), 1000);
	}
}