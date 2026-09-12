public without sharing class CreateOrderFromWaypoint {

	private final List<Id> waypointIds;
	private final List<Account> locations;

	private static final String KEY_FORMAT = '{0}-{1}-{2}-{3}-{4}';
	private Map<String, List<Collection_Waypoints__c>> waypointsByOrder = new Map<String, List<Collection_Waypoints__c>>();

	public CreateOrderFromWaypoint(List<Id> waypointIds) {
		this.waypointIds = waypointIds;
	}

	public CreateOrderFromWaypoint(List<Account> locations) {
		this.locations = locations;
	}

	public void create() {
		if (waypointIds != null) {
			create(getWaypoints(waypointIds));
		} else {
			create(getWaypoints(locations));
		}
	}

	private List<Collection_Waypoints__c> getWaypoints(List<Id> waypointIds) {
		return [SELECT Collection_Quantity__c, Daily_Dispatch__r.CreatedDate, Location__c, Location__r.Price_Book__c, Supplier__c, Supplier__r.Name, Supplier_Product__r.Product__c, Type__c, SupplierUnitPrice__c,
				Manual_Price__c, Discount_Type__c, Account_Discount__c, Account_Discount__r.BID_Price__c, Account_Discount__r.Product_Discount__c, Collection_Schedule__r.Po_Number__c, Collection_Schedule__r.Po_Number_Supplier__c,
				Case__r.Facility__c, Case__r.CalloutChargeProduct__c, CreatedDate
			FROM Collection_Waypoints__c
			WHERE Id IN :waypointIds AND Order_Created__c = false AND Location__r.Enqix_Dead_Live__c = 'Live'
			ORDER BY Location__c];
	}

	private List<Collection_Waypoints__c> getWaypoints(List<Account> locations) {
		return [SELECT Collection_Quantity__c, Daily_Dispatch__r.CreatedDate, Location__c, Location__r.Price_Book__c, Supplier__c, Supplier__r.Name, Supplier_Product__r.Product__c, Type__c, SupplierUnitPrice__c,
				Manual_Price__c, Discount_Type__c, Account_Discount__c, Account_Discount__r.BID_Price__c, Account_Discount__r.Product_Discount__c, Collection_Schedule__r.Po_Number__c, Collection_Schedule__r.Po_Number_Supplier__c,
                Collection_Schedule__r.Facility__c, Case__r.CalloutChargeProduct__c, CreatedDate
			FROM Collection_Waypoints__c
			WHERE Location__c IN :locations AND Order_Created__c = false AND Location__r.Enqix_Dead_Live__c = 'Live'
				AND Is_bin_collection__c = true AND Type__c = 'Normal' AND (Daily_Dispatch__r.EndTime__c = TODAY OR Daily_Dispatch__r.EndTime__c = YESTERDAY)
			ORDER BY Location__c];
	}

	private void create(List<Collection_Waypoints__c> waypoints) {
		for (Collection_Waypoints__c waypoint : waypoints) {
			String orderKey = getUniqueOrderKey(waypoint);
			if (!waypointsByOrder.containsKey(orderKey)) {
				waypointsByOrder.put(orderKey, new List<Collection_Waypoints__c>());
			}
			waypointsByOrder.get(orderKey).add(waypoint);
		}

		insertOrderItems(insertOrders());
	}

	private String getUniqueOrderKey(Collection_Waypoints__c waypoint) {
		String poNumber = waypoint.Collection_Schedule__r?.Po_Number__c;
		String supplierPoNumber = waypoint.Collection_Schedule__r?.Po_Number_Supplier__c;
		return String.format(KEY_FORMAT, new Object[]{waypoint.Daily_Dispatch__r.CreatedDate.date().format(), waypoint.Location__c, waypoint.Supplier__c, String.isNotBlank(poNumber) ? poNumber : null, String.isNotBlank(supplierPoNumber) ? supplierPoNumber : null});
	}

	private String getUniqueOrderKey(Order order) {
		return String.format(KEY_FORMAT, new Object[]{order.EffectiveDate.format(), order.AccountId, order.Supplier__c, String.isNotBlank(order.Po_Number__c) ? order.Po_Number__c : null, String.isNotBlank(order.PO_from_Supplier__c) ? order.PO_from_Supplier__c : null});
	}

	private List<Order> insertOrders() {
		List<Order> orders = new List<Order>();

		for (String orderKey : waypointsByOrder.keySet()) {
			orders.add(OrderUtil.createOrder(waypointsByOrder.get(orderKey)[0]));
		}

		Database.SaveResult[] results = Database.insert(orders, false);
		LogRegister.createLogsUpsert(results, orders, 'Orders from Waypoint', 'Insert', 'Order', 'AccountId');

		return orders;
	}

	private List<OrderItem> insertOrderItems(List<Order> orders) {
		List<OrderItem> orderItems = new List<OrderItem>();

		for (Order order : orders) {
			for (Collection_Waypoints__c waypoint : waypointsByOrder.get(getUniqueOrderKey(order))) {
				OrderItem orderItem = OrderUtil.createOrderItem(order, waypoint);
				if (waypoint.Type__c == 'Normal') {
					orderItem.Facility__c = waypoint.Collection_Schedule__r.Facility__c;
				} else if (waypoint.Type__c == 'Extra') {
					orderItem.Facility__c = waypoint.Case__r.Facility__c;
				}

				orderItems.add(orderItem);

				if (waypoint.Case__r?.CalloutChargeProduct__c != null) {
					orderItems.add(OrderUtil.createOrderItem(order.Id, waypoint.Case__r.CalloutChargeProduct__c, 1, waypoint.Location__r.Price_Book__c));
				}
			}
		}

		Database.SaveResult[] results1 = Database.insert(orderItems, false);
		LogRegister.createLogsUpsert(results1, orderItems, 'OrderItems from Waypoint', 'Insert', 'OrderItem', 'OrderId');

		OrderUtil.setBinOrderAsConfirmed(orders);
		Database.SaveResult[] results2 = Database.update(orders, false);
		LogRegister.createLogsUpsert(results2, orders, 'Set Waypoint Orders to Confirmed status', 'Update', 'Order', 'AccountId');

		markOrderCreated(orderItems);

		return orderItems;
	}

	private void markOrderCreated(List<OrderItem> orderItems) {
		List<Collection_Waypoints__c> waypoints = new List<Collection_Waypoints__c>();

		for (Collection_Waypoints__c waypoint : [SELECT Id, Location__c FROM Collection_Waypoints__c WHERE ID IN (SELECT Collection_Waypoint__c FROM OrderItem WHERE Id IN :orderItems)]) {
			waypoint.Order_Created__c = true;
			waypoints.add(waypoint);
		}

		if (!waypoints.isEmpty()) {
			Database.SaveResult[] results = Database.update(waypoints, false);
			LogRegister.createLogsUpsert(results, waypoints, 'Set Waypoints as Order Created', 'Update', 'Collection_Waypoints__c', 'Location__c');
		}
	}
}