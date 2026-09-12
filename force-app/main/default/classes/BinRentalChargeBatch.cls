public without sharing class BinRentalChargeBatch implements Database.Batchable<sObject> {

	private final Id STANDARD_PRICEBOOK_ID = PriceBookUtil.STANDARD_PRICEBOOK_ID;
	private final Suppliers__c FIRST_MILE_SUPPLIER = SupplierUtil.FIRST_MILE_SUPPLIER;
	private final Date START_DATE;
	private final Date END_DATE;

	private Map<Id, Account> locationsMap = new Map<Id, Account>();
	private Map<Id, Id> productIdToBinRentalIdMap = new Map<Id, Id>();
	private Map<String, Map<Id, Decimal>> locationToRentalBinQuantityMap = new Map<String, Map<Id, Decimal>>();

	public BinRentalChargeBatch() {
		Date today = Date.today();
		START_DATE = today.day() == 1 ? today.addMonths(-1) : today.toStartOfMonth();
		END_DATE = START_DATE.addMonths(1).addDays(-1);
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT Id, (SELECT Id FROM Recurrings__r WHERE Active__c = true) FROM Account WHERE Id IN
			(SELECT Location__c FROM Collection_Waypoints__c WHERE Location__r.Parent.MonthsInvoicedInAdvance__c = null AND Location__r.IsLive__c = true
			AND Collection_Schedule__r.Is_bin_collection__c = true AND Location__r.Parent.IsBinRentalExempt__c = false AND Supplier_Product__r.Product__r.BinRentalProduct__c != null
			AND DAY_ONLY(CreatedDate) >= :START_DATE AND DAY_ONLY(CreatedDate) <= :END_DATE)]);
	}

	public void execute(Database.BatchableContext batchContext, List<Account> locations) {
		filterLocations(locations);
		loadBinRentalMaps();

		insertBinRentalOrderItems(insertBinRentalOrders());
	}

	private void filterLocations(List<Account> locations) {
		for (Account location : locations) {
			if (location.Recurrings__r.isEmpty()){
				locationsMap.put(location.Id, location);
			}
		}
	}

	private List<Collection_Waypoints__c> fetchWaypoints() {
		return [SELECT Location__c, Collection_Quantity__c, Supplier_Product__r.Product__c, Supplier_Product__r.Product__r.BinRentalProduct__c
			FROM Collection_Waypoints__c WHERE Location__c IN :locationsMap.keySet()
			AND Collection_Schedule__r.Is_bin_collection__c = true AND Supplier_Product__r.Product__r.BinRentalProduct__c != null
			AND DAY_ONLY(CreatedDate) >= :START_DATE AND DAY_ONLY(CreatedDate) <= :END_DATE
			ORDER BY Location__c, Supplier_Product__r.Product__c];
	}

	private void loadBinRentalMaps() {
		List<Collection_Waypoints__c> waypoints = fetchWaypoints();

		Map<String, Map<Id, Decimal>> locationToProductQuantityMap = new Map<String, Map<Id, Decimal>>();
		Decimal quantity;
		for (Collection_Waypoints__c waypoint : waypoints) {
			if (!locationToProductQuantityMap.containsKey(waypoint.Location__c)) {
				locationToProductQuantityMap.put(waypoint.Location__c, new Map<Id, Decimal>());
			}

			quantity = locationToProductQuantityMap.get(waypoint.Location__c).get(waypoint.Supplier_Product__r.Product__c);
			if (quantity == null || waypoint.Collection_Quantity__c > quantity) {
				locationToProductQuantityMap.get(waypoint.Location__c).put(waypoint.Supplier_Product__r.Product__c, waypoint.Collection_Quantity__c);
			}

			productIdToBinRentalIdMap.put(waypoint.Supplier_Product__r.Product__c, waypoint.Supplier_Product__r.Product__r.BinRentalProduct__c);
		}

		loadRentalProductToQuantityMap(locationToProductQuantityMap);
	}

	private void loadRentalProductToQuantityMap(Map<String, Map<Id, Decimal>> locationToProductQuantityMap) {
		for (Id locationId : locationToProductQuantityMap.keySet()) {
			Map<Id, Decimal> rentalProductToQuantityMap = new Map<Id, Decimal>();
			Map<Id, Decimal> productToQuantityMap = locationToProductQuantityMap.get(locationId);
			Id binRentalProductId;
			for (Id productId : productToQuantityMap.keySet()) {
				binRentalProductId = productIdToBinRentalIdMap.get(productId);
				if (!rentalProductToQuantityMap.containsKey(binRentalProductId)) {
					rentalProductToQuantityMap.put(binRentalProductId, productToQuantityMap.get(productId));
				} else {
					rentalProductToQuantityMap.put(binRentalProductId, rentalProductToQuantityMap.get(binRentalProductId) + productToQuantityMap.get(productId));
				}
			}

			locationToRentalBinQuantityMap.put(locationId, rentalProductToQuantityMap);
		}
	}

	private Map<Id, Order> insertBinRentalOrders() {
		Map<Id, Order> locationToOrderMap = new Map<Id, Order>();
		for (Id locationId : locationToRentalBinQuantityMap.keySet()) {
			Order order  = OrderUtil.createOrder(locationId, FIRST_MILE_SUPPLIER, END_DATE);
			order.PeriodStart__c = START_DATE;
			order.PeriodEnd__c = END_DATE;
			locationToOrderMap.put(locationId, order);
		}

		Database.SaveResult[] results = Database.insert(locationToOrderMap.values(), false);
		LogRegister.createLogsUpsert(results, locationToOrderMap.values(), 'Monthly Bin Rental Orders', 'Insert', 'Order', 'AccountId');

		return locationToOrderMap;
	}

	private void insertBinRentalOrderItems(Map<Id, Order> locationToOrderMap) {
		List<OrderItem> orderItems = new List<OrderItem>();
		for (Id locationId : locationToOrderMap.keySet()) {
			Map<Id, Decimal> rentalProductToQuantityMap = locationToRentalBinQuantityMap.get(locationId);

			for (Id binRentalProductId : rentalProductToQuantityMap.keySet()) {
				orderItems.add(OrderUtil.createOrderItem(locationToOrderMap.get(locationId).Id, binRentalProductId, rentalProductToQuantityMap.get(binRentalProductId), STANDARD_PRICEBOOK_ID, null, null, null, FIRST_MILE_SUPPLIER.Id));
			}
		}

		Database.SaveResult[] results = Database.insert(orderItems, false);
		LogRegister.createLogsUpsert(results, orderItems, 'Monthly Bin Rental OrderItems', 'Insert', 'OrderItem', 'OrderId');

		OrderUtil.setBinOrderAsConfirmed(locationToOrderMap.values());
		Database.SaveResult[] results1 = Database.update(locationToOrderMap.values(), false);
		LogRegister.createLogsUpsert(results1, locationToOrderMap.values(), 'Set Monthly Bin Rental Orders to Confirmed status', 'Update', 'Order', 'AccountId');
	}

	public void finish(Database.BatchableContext batchContext) {}
}