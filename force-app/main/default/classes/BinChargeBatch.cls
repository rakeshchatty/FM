public without sharing class BinChargeBatch implements Database.Batchable<sObject>, Database.Stateful {

	private Map<String, Product2> categoryCodeToProductMap = new Map<String, Product2>();

	private Id FIRSTMILE_SUPPLIER_ID;
	private Id GENERAL_WASTE_CATEGORY;
	private Id MIXED_RECYCLING_CATEGORY;
	private Id FOOD_CATEGORY;
	private Id GLASS_CATEGORY;
	private Id GENERAL_WASTE_CHARGE;
	private Id MIXED_RECYCLING_CHARGE;
	private Id FOOD_CHARGE;
	private Id GLASS_CHARGE;
	private Date YESTERDAY;
	private String MONTH;
	private String YEAR;

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		FIRSTMILE_SUPPLIER_ID = [SELECT Id FROM Suppliers__c WHERE Name = 'First Mile Ltd'].Id;

		OverweightSetting__c overweightSetting = OverweightSetting__c.getOrgDefaults();
		GENERAL_WASTE_CATEGORY = overweightSetting.GeneralWasteProductCategoryId__c;
		MIXED_RECYCLING_CATEGORY = overweightSetting.MixedRecyclingProductCategoryId__c;
		FOOD_CATEGORY = overweightSetting.FoodProductCategoryId__c;
		GLASS_CATEGORY = overweightSetting.GlassProductCategoryId__c;
		GENERAL_WASTE_CHARGE = overweightSetting.GeneralWasteChargeProductId__c;
		MIXED_RECYCLING_CHARGE = overweightSetting.MixedRecyclingChargeProductId__c;
		FOOD_CHARGE = overweightSetting.FoodChargeProductId__c;
		GLASS_CHARGE = overweightSetting.GlassChargeProductId__c;

		YESTERDAY = System.today() - 1;
		MONTH = String.valueOf('0' + YESTERDAY.month()).right(2);
		YEAR = String.valueOf(YESTERDAY.year());

		for (Product2 product : [SELECT BinCategoryCode__c, Product_Category__c FROM Product2 WHERE BinCategoryCode__c != null]) {
			categoryCodeToProductMap.put(product.BinCategoryCode__c, product);
		}

		String query = 'SELECT Id, Price_Book__c FROM Account WHERE Id IN (SELECT Location__c FROM BinSummary__c WHERE Month__c = :MONTH AND Year__c = :YEAR AND (Excess__c > 0 OR UnmatchedOverweight__c > 0))';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> locations) {
		Map<Id, Account> locationMap = new Map<Id, Account>(locations);

		Map<Id, Order> orderMap = insertOrders(locations);
		List<OrderItem> orderItems = new List<OrderItem>();
		orderItems.addAll(createExcessBinOrderItems(orderMap, locationMap));
		orderItems.addAll(createUnmatchedOverweightChargeOrderItems(orderMap, locationMap));
		INSERT orderItems;

		for (Order order : orderMap.values()) {
			order.Status = 'Delivered';
		}
		UPDATE orderMap.values();
	}

	public void finish(Database.BatchableContext BC) {}

	private Map<Id, Order> insertOrders(List<Account> locations) {
		Map<Id, Order> orderMap = new Map<Id, Order>();
		for (Account location : locations) {
			orderMap.put(location.Id, new Order(AccountId = location.Id, EffectiveDate = YESTERDAY, Delivery_Date__c = YESTERDAY, Requested_Delivery_Date__c = YESTERDAY,
				Status = 'Draft', IsBinCollection__c = true, ConfirmationEmailStatus__c = 'Do Not Send'));
		}

		INSERT orderMap.values();

		return orderMap;
	}

	private List<OrderItem> createExcessBinOrderItems(Map<Id, Order> orderMap, Map<Id, Account> locationMap) {
		List<AggregateResult> aggregateResults = [SELECT Location__c, CategoryCode__c, SUM(Excess__c) Quantity FROM BinSummary__c
			WHERE Location__c IN :locationMap.keySet() AND Excess__c > 0 AND Month__c = :MONTH AND Year__c = :YEAR
			GROUP BY Location__c, CategoryCode__c];
		if (aggregateResults.isEmpty()) {
			return new List<OrderItem>();
		}

		Map<String, Collection_Waypoints__c> waypointMap = fetchWaypointMap(aggregateResults);

		List<OrderItem> orderItems = new List<OrderItem>();
		Id locationId;
		String categoryCode;
		for (AggregateResult aggregateResult : aggregateResults) {
			locationId = (Id)aggregateResult.get('Location__c');
			categoryCode = (String)aggregateResult.get('CategoryCode__c');
			Collection_Waypoints__c waypoint = waypointMap.get(locationId + '-' + categoryCode);
			if (waypoint != null) {
				orderItems.add(OrderUtil.createOrderItem(orderMap.get(locationId).Id, categoryCodeToProductMap.get(categoryCode).Id, (Decimal)aggregateResult.get('Quantity'), locationMap.get(locationId).Price_Book__c, waypoint.Manual_Price__c, waypoint.Discount_Type__c, waypoint.Account_Discount__r, FIRSTMILE_SUPPLIER_ID));
			} else {
				orderItems.add(OrderUtil.createOrderItem(orderMap.get(locationId).Id, categoryCodeToProductMap.get(categoryCode).Id, (Decimal)aggregateResult.get('Quantity'), locationMap.get(locationId).Price_Book__c, null, null, null, FIRSTMILE_SUPPLIER_ID));
			}
		}

		return orderItems;
	}

	private List<OrderItem> createUnmatchedOverweightChargeOrderItems(Map<Id, Order> orderMap, Map<Id, Account> locationMap) {
		List<AggregateResult> aggregateResults = [SELECT Location__c, CategoryCode__c, SUM(Overweight__c) Overweight FROM BinWeight__c
			WHERE Location__c IN :locationMap.keySet() AND Status__c = 'No match' AND Overweight__c > 0 AND CreatedDate = LAST_MONTH
			GROUP BY Location__c, CategoryCode__c];
		if (aggregateResults.isEmpty()) {
			return new List<OrderItem>();
		}

		Map<Id, Decimal> locationGeneralWasteMap = new Map<Id, Decimal>();
		Map<Id, Decimal> locationMixedWasteMap = new Map<Id, Decimal>();
		Map<Id, Decimal> locationFoodWasteMap = new Map<Id, Decimal>();
		Map<Id, Decimal> locationGlassWasteMap = new Map<Id, Decimal>();
		Id locationId;
		Decimal overweight;
		for (AggregateResult aggregateResult : aggregateResults) {
			locationId = (Id)aggregateResult.get('Location__c');
			overweight = (Decimal)aggregateResult.get('Overweight');
			Product2 product = categoryCodeToProductMap.get((String)aggregateResult.get('CategoryCode__c'));
			if (product.Product_Category__c == GENERAL_WASTE_CATEGORY) {
				Decimal weight = locationGeneralWasteMap.containsKey(locationId) ? locationGeneralWasteMap.get(locationId) + overweight : overweight;
				locationGeneralWasteMap.put(locationId, weight);
			} else if (product.Product_Category__c == MIXED_RECYCLING_CATEGORY) {
				Decimal weight = locationMixedWasteMap.containsKey(locationId) ? locationMixedWasteMap.get(locationId) + overweight : overweight;
				locationMixedWasteMap.put(locationId, weight);
			} else if (product.Product_Category__c == FOOD_CATEGORY) {
				Decimal weight = locationFoodWasteMap.containsKey(locationId) ? locationFoodWasteMap.get(locationId) + overweight : overweight;
				locationFoodWasteMap.put(locationId, weight);
			} else if (product.Product_Category__c == GLASS_CATEGORY) {
				Decimal weight = locationGlassWasteMap.containsKey(locationId) ? locationGlassWasteMap.get(locationId) + overweight : overweight;
				locationGlassWasteMap.put(locationId, weight);
			}
		}

		List<OrderItem> orderItems = new List<OrderItem>();
		for (Account location : locationMap.values()) {
			if (locationGeneralWasteMap.containsKey(location.Id)) {
				orderItems.add(OrderUtil.createOrderItem(orderMap.get(location.Id).Id, GENERAL_WASTE_CHARGE, locationGeneralWasteMap.get(location.Id), location.Price_Book__c));
			}
			if (locationMixedWasteMap.containsKey(location.Id)) {
				orderItems.add(OrderUtil.createOrderItem(orderMap.get(location.Id).Id, MIXED_RECYCLING_CHARGE, locationMixedWasteMap.get(location.Id), location.Price_Book__c));
			}
			if (locationFoodWasteMap.containsKey(location.Id)) {
				orderItems.add(OrderUtil.createOrderItem(orderMap.get(location.Id).Id, FOOD_CHARGE, locationFoodWasteMap.get(location.Id), location.Price_Book__c));
			}
			if (locationGlassWasteMap.containsKey(location.Id)) {
				orderItems.add(OrderUtil.createOrderItem(orderMap.get(location.Id).Id, GLASS_CHARGE, locationGlassWasteMap.get(location.Id), location.Price_Book__c));
			}
		}

		return orderItems;
	}

	private Map<String, Collection_Waypoints__c> fetchWaypointMap(List<AggregateResult> binSummaryAggregateResults) {
		List<String> binKeys = new List<String>();
		for (AggregateResult aggregateResult : binSummaryAggregateResults) {
			binKeys.add((String)aggregateResult.get('Location__c') + '-' + (String)aggregateResult.get('CategoryCode__c') + '-' + YEAR + '-' + MONTH);
		}

		List<AggregateResult> waypointAggregateResults = [SELECT MAX(Id) WaypointId FROM Collection_Waypoints__c WHERE BinKey__c IN :binKeys GROUP BY BinKey__c];
		List<Id> waypointIds = new List<Id>();
		for (AggregateResult aggregateResult : waypointAggregateResults) {
			waypointIds.add((Id)aggregateResult.get('WaypointId'));
		}

		Map<String, Collection_Waypoints__c> waypointMap = new Map<String, Collection_Waypoints__c>();
		for (Collection_Waypoints__c waypoint : [SELECT Location__c, Discount_Type__c, Account_Discount__r.BID_Price__c, Account_Discount__r.Product_Discount__c, Manual_Price__c, Supplier_Product__r.Product__r.BinCategoryCode__c FROM Collection_Waypoints__c WHERE Id IN: waypointIds]) {
			waypointMap.put(waypoint.Location__c + '-' + waypoint.Supplier_Product__r.Product__r.BinCategoryCode__c, waypoint);
		}

		return waypointMap;
	}
}