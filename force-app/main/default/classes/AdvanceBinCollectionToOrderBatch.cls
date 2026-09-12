public without sharing class AdvanceBinCollectionToOrderBatch implements Database.Batchable<sObject> {

	private Integer CURRENT_INDEX;
	private final List<Integer> MONTHS_INVOICED_IN_ADVANCE;
	private final Integer MONTHS;
	private final Date START_DATE;
	private final Date END_DATE;
	private final String ORDER_KEY_FORMAT = '{0}-{1}-{2}';

	private final Id STANDARD_PRICEBOOK_ID = PriceBookUtil.STANDARD_PRICEBOOK_ID;
	private final Suppliers__c FIRST_MILE_SUPPLIER = SupplierUtil.FIRST_MILE_SUPPLIER;

	private Map<String, Account_Discount__c> accountDiscounts = new Map <String, Account_Discount__c>();
	private Map<String, Account_Discount__c> partnerDiscounts = new Map <String, Account_Discount__c>();
	private Map<String, List<Schedule__c>> orderKeyToSchedulesMap = new Map<String, List<Schedule__c>>();
	private Map<Id, Set<Date>> scheduleToDatesMap = new Map<Id, Set<Date>>();
	private Map<String, Map<Id, Decimal>> locationToRentalBinQuantityMap = new Map<String, Map<Id, Decimal>>();
	private Map<Id, Id> productIdToBinRentalIdMap = new Map<Id, Id>();
	private Map<Id, Account> locationsMap;
	private Map<String, Order> orderKeyToOrderMap = new Map<String, Order>();
	private Map<Id, Order> locationToBinRentalOrderMap = new Map<Id, Order>();
	private Map<Id, List<ScheduleSuspension__c>> aggregatorToSuspensionsMap = new Map<Id, List<ScheduleSuspension__c>>();

	public AdvanceBinCollectionToOrderBatch() {
		this(getMonthsInvoicedInAdvance(), 0);
	}

	private AdvanceBinCollectionToOrderBatch(List<Integer> monthsInvoicedInAdvance, Integer currentIndex) {
		CURRENT_INDEX = currentIndex;
		MONTHS_INVOICED_IN_ADVANCE = monthsInvoicedInAdvance;
		MONTHS = MONTHS_INVOICED_IN_ADVANCE[CURRENT_INDEX];
		Date today = Date.today();
		START_DATE = today.day() == 1 ? today : today.addMonths(1).toStartOfMonth();
		END_DATE = START_DATE.addMonths(MONTHS).addDays(-1);
	}

	private static List<Integer> getMonthsInvoicedInAdvance() {
		List<Integer> monthsInvoicedInAdvance = new List<Integer>();
		for(Schema.PicklistEntry month : Account.MonthsInvoicedInAdvance__c.getDescribe().getPicklistValues()) {
			monthsInvoicedInAdvance.add(Integer.valueOf(month.getValue()));
		}

		return monthsInvoicedInAdvance;
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		return Database.getQueryLocator([SELECT Id, Price_Book__c, Parent.IsBinRentalExempt__c, (SELECT Id FROM Recurrings__r WHERE Active__c = true) FROM Account WHERE Id IN
			(SELECT Location__c FROM Schedule__c WHERE Location__r.Parent.MonthsInvoicedInAdvance__c = :String.valueOf(MONTHS) AND Location__r.IsLive__c = true  AND Location__r.Parent.NextAdvanceInvoiceDate__c = :START_DATE
			AND Is_bin_collection__c = true AND (Start_Date__c = null OR Start_Date__c <= :END_DATE) AND (End_Date__c = null OR End_Date__c >= :START_DATE))]);
	}

	public void execute(Database.BatchableContext batchContext, List<Account> locations) {
		Set<Id> accountIds = new Set<Id>();
		Set<Id> accountProductsIds = new Set<Id>();
		Set<Id> partnerIds = new Set<Id>();
		Set<Id> partnerProductsIds = new Set<Id>();
		locationsMap = new Map<Id, Account>(locations);

		List<Schedule__c> schedules = fetchSchedules();
		loadOrderKeyToSchedulesMap(schedules);
		loadAggregatorToSuspensionsMap(schedules);
		loadScheduleToDatesMap();
		loadBinRentalMap(schedules);

		for (String orderKey : orderKeyToSchedulesMap.keySet()) {
			for (Schedule__c schedule : orderKeyToSchedulesMap.get(orderKey)) {
				if (schedule.Discount_Type__c == 'Partner' && schedule.Location__r.Partnership__c != null) {
					partnerIds.add(schedule.Location__r.Partnership__c);
					partnerProductsIds.add(schedule.Supplier_Product__r.Product__c);
				} else if (schedule.Discount_Type__c == 'Account') {
					accountIds.add(schedule.Location__r.ParentId);
					accountProductsIds.add(schedule.Supplier_Product__r.Product__c);
				}
			}
		}

		partnerDiscounts = AccountUtil.getDiscounts(partnerIds, partnerProductsIds);
		accountDiscounts = AccountUtil.getDiscounts(accountIds, accountProductsIds);

		createOrders();
		createBinRentalOrders();

		List<Order> orders = new List<Order>();
		orders.addAll(orderKeyToOrderMap.values());
		orders.addAll(locationToBinRentalOrderMap.values());
		Database.SaveResult[] results = Database.insert(orders, false);
		LogRegister.createLogsUpsert(results, orders, 'Advance Bin Collection and Bin Rental Orders', 'Insert', 'Order', 'AccountId');

		List<OrderItem> orderItems = new List<OrderItem>();
		orderItems.addAll(createOrderItems());
		orderItems.addAll(createBinRentalOrderItems());

		Database.SaveResult[] results1 = Database.insert(orderItems, false);
		LogRegister.createLogsUpsert(results1, orderItems, 'OrderItems added to Advance Bin Collection and Bin Rental Orders', 'Insert', 'OrderItem', 'OrderId');

		OrderUtil.setBinOrderAsConfirmed(orders);
		Database.SaveResult[] results2 = Database.update(orders, false);
		LogRegister.createLogsUpsert(results2, orders, 'Set Advance Bin Collection and Bin Rental Orders to Confirmed status', 'Update', 'Order', 'AccountId');
	}

	private List<Schedule__c> fetchSchedules() {
		return [SELECT Location__c, Location__r.ParentId, Location__r.Partnership__c, Location__r.Price_Book__c,
			Supplier__c, Supplier__r.Name, Supplier_Product__r.Product__c, Supplier_Product__r.Product__r.BinRentalProduct__c,
			Collection_Quantity__c, Discount_Type__c, Enqix_Price__c, Days__c, SupplierUnitPrice__c,
			Start_Date__c, End_Date__c, WeekFrequency__c, PreviousCollectionDate__c, Po_Number__c, CollectionAggregator__c, Po_Number_Supplier__c
			FROM Schedule__c WHERE Location__c IN :locationsMap.keySet() AND Is_bin_collection__c = true
			AND (Start_Date__c = null OR Start_Date__c <= :END_DATE) AND (End_Date__c = null OR End_Date__c >= :START_DATE)
			ORDER BY Location__c];
	}

	private void loadOrderKeyToSchedulesMap(List<Schedule__c> schedules) {
		String orderKey;
		for (Schedule__c schedule : schedules) {
			orderKey = getUniqueOrderKey(schedule);
			if (!orderKeyToSchedulesMap.containsKey(orderKey)) {
				orderKeyToSchedulesMap.put(orderKey, new List<Schedule__c>());
			}
			orderKeyToSchedulesMap.get(orderKey).add(schedule);
		}
	}

	@TestVisible
	private void loadAggregatorToSuspensionsMap(List<Schedule__c> schedules) {
		Set<Id> aggregatorIds = IdUtil.extractId(schedules, 'CollectionAggregator__c');
		List<ScheduleSuspension__c> suspensions = [SELECT Aggregator__c, SuspensionDate__c, ReactivationDate__c FROM ScheduleSuspension__c WHERE IsActive__c = true AND Aggregator__c IN :aggregatorIds];
		for (ScheduleSuspension__c suspension : suspensions) {
			if (!aggregatorToSuspensionsMap.containsKey(suspension.Aggregator__c)) {
				aggregatorToSuspensionsMap.put(suspension.Aggregator__c, new List<ScheduleSuspension__c>());
			}
			aggregatorToSuspensionsMap.get(suspension.Aggregator__c).add(suspension);
		}
	}

	private void loadBinRentalMap(List<Schedule__c> schedules) {
		Map<String, Map<Id, Decimal>> locationToProductQuantityMap = new Map<String, Map<Id, Decimal>>();

		Decimal quantity;
		for (Schedule__c schedule : schedules) {
			if (isBinRentalExempt(schedule, locationsMap.get(schedule.Location__c))) {
				continue;
			}

			if (!locationToProductQuantityMap.containsKey(schedule.Location__c)) {
				locationToProductQuantityMap.put(schedule.Location__c, new Map<Id, Decimal>());
			}

			quantity = locationToProductQuantityMap.get(schedule.Location__c).get(schedule.Supplier_Product__r.Product__c);
			if (quantity == null || schedule.Collection_Quantity__c > quantity) {
				locationToProductQuantityMap.get(schedule.Location__c).put(schedule.Supplier_Product__r.Product__c, schedule.Collection_Quantity__c);
			}

			productIdToBinRentalIdMap.put(schedule.Supplier_Product__r.Product__c, schedule.Supplier_Product__r.Product__r.BinRentalProduct__c);
		}

		for (Id locationId : locationToProductQuantityMap.keySet()) {
			locationToRentalBinQuantityMap.put(locationId, extractRentalProductToQuantityMap(locationToProductQuantityMap.get(locationId)));
		}
	}

	private Map<Id, Decimal> extractRentalProductToQuantityMap(Map<Id, Decimal> productToQuantityMap) {
		Map<Id, Decimal> rentalProductToQuantityMap = new Map<Id, Decimal>();
		Id binRentalProductId;
		for (Id productId : productToQuantityMap.keySet()) {
			binRentalProductId = productIdToBinRentalIdMap.get(productId);
			if (!rentalProductToQuantityMap.containsKey(binRentalProductId)) {
				rentalProductToQuantityMap.put(binRentalProductId, productToQuantityMap.get(productId));
			} else {
				rentalProductToQuantityMap.put(binRentalProductId, rentalProductToQuantityMap.get(binRentalProductId) + productToQuantityMap.get(productId));
			}
		}

		return rentalProductToQuantityMap;
	}

	private Boolean isBinRentalExempt(Schedule__c schedule, Account location) {
		return location.Parent.IsBinRentalExempt__c || !location.Recurrings__r.isEmpty() || schedule.Supplier_Product__r.Product__r.BinRentalProduct__c == null;
	}

	private String getUniqueOrderKey(Schedule__c schedule) {
		return String.format(ORDER_KEY_FORMAT, new Object[]{schedule.Location__c, schedule.Supplier__c, String.isNotBlank(schedule.Po_Number__c) ? schedule.Po_Number__c : null});
	}

	private void loadScheduleToDatesMap() {
		for (String orderKey : orderKeyToSchedulesMap.keySet()) {
			for (Schedule__c schedule : orderKeyToSchedulesMap.get(orderKey)) {
				scheduleToDatesMap.put(schedule.Id, getCollectionDates(schedule));
			}
		}
	}

	@TestVisible
	private Set<Date> getCollectionDates(Schedule__c schedule) {
		Date startDate = schedule.Start_Date__c == null || schedule.Start_Date__c < START_DATE ? START_DATE : schedule.Start_Date__c;
		Date endDate = schedule.End_Date__c == null || schedule.End_Date__c > END_DATE ? END_DATE : schedule.End_Date__c;
		DateUtil.Day dayOfWeek = DateUtil.Day.valueOf(schedule.Days__c);
		Set<Date> collectionDates = DateUtil.getDates(startDate, endDate, dayOfWeek, Integer.valueOf(schedule.WeekFrequency__c), schedule.PreviousCollectionDate__c);

		List<ScheduleSuspension__c> suspensions = aggregatorToSuspensionsMap.get(schedule.CollectionAggregator__c);
		if (suspensions == null || suspensions.isEmpty()) {
			return collectionDates;
		}

		Date suspensionStartDate, reactivationStartDate, suspensionEndDate;
		for (ScheduleSuspension__c suspension : suspensions) {
			suspensionStartDate = suspension.SuspensionDate__c;
			reactivationStartDate = suspension.ReactivationDate__c;
			if (suspensionStartDate <= endDate && reactivationStartDate > startDate) {
			suspensionStartDate = suspensionStartDate < startDate ? startDate : suspensionStartDate;
			suspensionEndDate = reactivationStartDate > endDate ? endDate : reactivationStartDate?.addDays(-1);
		}
			collectionDates.removeAll(DateUtil.getDates(suspensionStartDate, suspensionEndDate, dayOfWeek, null, null));
		}

		return collectionDates;
	}

	private void createOrders() {
		Schedule__c schedule;
		for (String orderKey : orderKeyToSchedulesMap.keySet()) {
			schedule = orderKeyToSchedulesMap.get(orderKey)[0];

			Order order = OrderUtil.createOrder(schedule, START_DATE);
			order.PeriodStart__c = START_DATE;
			order.PeriodEnd__c = END_DATE;
			order.IsAdvance__c = true;
			orderKeyToOrderMap.put(orderKey, order);
		}
	}

	private void createBinRentalOrders() {
		for (Id locationId : locationToRentalBinQuantityMap.keySet()) {
			Order order  = OrderUtil.createOrder(locationId, FIRST_MILE_SUPPLIER, START_DATE);
			order.PeriodStart__c = START_DATE;
			order.PeriodEnd__c = END_DATE;
			order.IsAdvance__c = true;
			order.Pricebook2Id = STANDARD_PRICEBOOK_ID;
			locationToBinRentalOrderMap.put(locationId, order);
		}
	}

	private List<OrderItem> createOrderItems() {
		List<OrderItem> orderItems = new List<OrderItem>();
		Order order;
		Account_Discount__c discount;

		for (String orderKey : orderKeyToSchedulesMap.keySet()) {
			order = orderKeyToOrderMap.get(orderKey);

			for (Schedule__c schedule : orderKeyToSchedulesMap.get(orderKey)) {
				if (schedule.Discount_Type__c == 'Partner') {
					discount = partnerDiscounts.get(schedule.Location__r.Partnership__c + '-' + schedule.Supplier_Product__r.Product__c);
				} else if (schedule.Discount_Type__c == 'Account') {
					discount = accountDiscounts.get(schedule.Location__r.ParentId + '-' + schedule.Supplier_Product__r.Product__c);
				}

				for (Date collectionDate : scheduleToDatesMap.get(schedule.Id)) {
					orderItems.add(OrderUtil.createOrderItem(order, schedule, discount, collectionDate));
				}
			}
		}

		return orderItems;
	}

	private List<OrderItem> createBinRentalOrderItems() {
		List<OrderItem> orderItems = new List<OrderItem>();
		for (Id locationId : locationToBinRentalOrderMap.keySet()) {
			Map<Id, Decimal> rentalProductToQuantityMap = locationToRentalBinQuantityMap.get(locationId);

			for (Id binRentalProductId : rentalProductToQuantityMap.keySet()) {
				orderItems.add(OrderUtil.createOrderItem(locationToBinRentalOrderMap.get(locationId).Id, binRentalProductId, rentalProductToQuantityMap.get(binRentalProductId) * MONTHS, STANDARD_PRICEBOOK_ID, null, null, null, FIRST_MILE_SUPPLIER.Id));
			}
		}

		return orderItems;
	}

	public void finish(Database.BatchableContext batchContext) {
		CURRENT_INDEX++;
		if (MONTHS_INVOICED_IN_ADVANCE.size() > CURRENT_INDEX) {
			Database.executeBatch(new AdvanceBinCollectionToOrderBatch(MONTHS_INVOICED_IN_ADVANCE, CURRENT_INDEX), 10);
		} else {
			Database.executeBatch(new NextAdvanceInvoiceDateBatch(START_DATE));
		}
	}
}