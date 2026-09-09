public without sharing class AdvanceBinCollectionToOrderBatch implements Database.Batchable<sObject> {

	private final Date TODAY = System.today(); // TO DO: what should be start date for quarterly?
	private final Date QUATER_END = DateUtil.getQuarterEndDate(TODAY);

	private final String ORDER_KEY_FORMAT = '{0}-{1}-{2}';
	private final String PRODUCT_KEY_FORMAT = '{0}-{1}-{2}-{3}';

	private Map<String, Account_Discount__c> accountDiscounts = new Map <String, Account_Discount__c>();
	private Map<String, Account_Discount__c> partnerDiscounts = new Map <String, Account_Discount__c>();
	private Map<String, List<ScheduleWrapper>> orderItemKeyMap = new Map<String, List<ScheduleWrapper>>();
	private Map<String, Integer> orderItemCollectionCountMap = new Map<String, Integer>();
	private Map<String, Order> orderMap = new Map<String, Order>();

	private Boolean isDelta;

	public AdvanceBinCollectionToOrderBatch(Boolean isDelta) {
		this.isDelta = isDelta;
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		// TO DO: Delta should not start on 1st of each quarter
		if (isDelta) {
			return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN
				(SELECT Location__c FROM ScheduleAdvanceInvoiceHistory__c WHERE CreatedDate = YESTERDAY
				AND (Schedule__r.Start_Date__c = null OR Schedule__r.Start_Date__c <= :QUATER_END) AND (Schedule__r.End_Date__c = null OR Schedule__r.End_Date__c >= :TODAY))]);
		} else {
			return Database.getQueryLocator([SELECT Id FROM Account WHERE Id IN
				(SELECT Location__c FROM Schedule__c WHERE Location__r.Parent.IsBinCollectionAdvanceInvoiced__c = true AND Location__r.IsLive__c = true
				AND Is_bin_collection__c = true AND (Start_Date__c = null OR Start_Date__c <= :QUATER_END) AND (End_Date__c = null OR End_Date__c >= :TODAY))]);
		}
	}

	public void execute(Database.BatchableContext batchContext, List<Account> locations) {
		Set<Id> accountIds = new Set<Id>();
		Set<Id> accountProductsIds = new Set<Id>();
		Set<Id> partnerIds = new Set<Id>();
		Set<Id> partnerProductsIds = new Set<Id>();

		loadOrderItemKeyMap(fetchSchedules(locations));
		loadCollectionCountMap();

		for (String key : orderItemKeyMap.keySet()) {
			Schedule__c schedule;
			for (ScheduleWrapper wrapper : orderItemKeyMap.get(key)) {
				schedule = wrapper.schedule;
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

		insertOrders();
		insertOrderItems();
	}

	private List<ScheduleWrapper> fetchSchedules(List<Account> locations) {
		List<ScheduleWrapper> schedules = new List<ScheduleWrapper>();
		if (isDelta) {
			for (ScheduleAdvanceInvoiceHistory__c history : [SELECT Quantity__c, IsNew__c, Schedule__r.Collection_Quantity__c, IsFortnightly__c, Schedule__r.Fortnightly__c,
				StartDate__c, Schedule__r.Start_Date__c, EndDate__c, Schedule__r.End_Date__c,
				SuspensionStartDate__c, Schedule__r.Suspension_Start_Date__c, ReactivationStartDate__c, Schedule__r.Reactivation_Start_Date__c,
				Schedule__r.Location__c, Schedule__r.Location__r.ParentId, Schedule__r.Location__r.Partnership__c, Schedule__r.Location__r.Price_Book__c,
				Schedule__r.Supplier__c, Schedule__r.Supplier__r.Name, Schedule__r.Supplier_Product__r.Product__c,
				Schedule__r.Discount_Type__c, Schedule__r.Enqix_Price__c, Schedule__r.Days__c, Schedule__r.Week_Off__c, Schedule__r.Po_Number__c
				FROM ScheduleAdvanceInvoiceHistory__c WHERE Location__c IN :locations AND CreatedDate = YESTERDAY
				AND (Schedule__r.Start_Date__c = null OR Schedule__r.Start_Date__c <= :QUATER_END) AND (Schedule__r.End_Date__c = null OR Schedule__r.End_Date__c >= :TODAY)
				ORDER BY Location__c]) {
				schedules.add(new ScheduleWrapper(history));
			}
		} else {
			for (Schedule__c schedule : [SELECT Location__c, Location__r.ParentId, Location__r.Partnership__c, Location__r.Price_Book__c,
				Supplier__c, Supplier__r.Name, Supplier_Product__r.Product__c, Collection_Quantity__c,
				Discount_Type__c, Enqix_Price__c, Days__c,
				Start_Date__c, End_Date__c, Suspension_Start_Date__c, Reactivation_Start_Date__c, Fortnightly__c, Week_Off__c, Po_Number__c
				FROM Schedule__c WHERE Location__c IN :locations
				AND Is_bin_collection__c = true AND (Start_Date__c = null OR Start_Date__c <= :QUATER_END) AND (End_Date__c = null OR End_Date__c >= :TODAY)
				ORDER BY Location__c]) {
				schedules.add(new ScheduleWrapper(schedule));
			}
		}
		return schedules;
	}

	private void loadOrderItemKeyMap(List<ScheduleWrapper> scheduleList) {
		String productKey;
		for (ScheduleWrapper wrapper : scheduleList) {
			productKey = getUniqueProductKey(wrapper.schedule);
			if (!orderItemKeyMap.containsKey(productKey)) {
				orderItemKeyMap.put(productKey, new List<ScheduleWrapper>());
			}
			orderItemKeyMap.get(productKey).add(wrapper);
		}
	}

	private String getUniqueOrderKey(Schedule__c schedule) {
		return String.format(ORDER_KEY_FORMAT, new Object[]{schedule.Location__c, schedule.Supplier__c, String.isNotBlank(schedule.Po_Number__c) ? schedule.Po_Number__c : null});
	}

	private String getUniqueProductKey(Schedule__c schedule) {
		return String.format(PRODUCT_KEY_FORMAT, new Object[]{getUniqueOrderKey(schedule), schedule.Supplier_Product__r.Product__c, schedule.Discount_Type__c, schedule.Enqix_Price__c});
	}

	private void loadCollectionCountMap() {
		if (isDelta) {
			Set<String> orderItemKeysToRemove = new Set<String>();
			for (String key : orderItemKeyMap.keySet()) {
				Decimal quantity = 0;
				Schedule__c schedule;
				ScheduleAdvanceInvoiceHistory__c history;
				for (ScheduleWrapper wrapper : orderItemKeyMap.get(key)) {
					schedule = wrapper.schedule;
					history = wrapper.history;
					Integer currentCount = countCollections(schedule.Start_Date__c, schedule.End_Date__c, schedule.Suspension_Start_Date__c, schedule.Reactivation_Start_Date__c, schedule.Days__c, schedule.Fortnightly__c, schedule.Week_Off__c, schedule.Collection_Quantity__c);
					Integer previousCount = history.IsNew__c ? 0 : countCollections(history.StartDate__c, history.EndDate__c, history.SuspensionStartDate__c, history.ReactivationStartDate__c, schedule.Days__c, schedule.Fortnightly__c, schedule.Week_Off__c, history.Quantity__c);
					quantity += currentCount - previousCount;
				}

				if (quantity > 0) {
					orderItemCollectionCountMap.put(key, quantity.intValue());
				} else {
					orderItemKeysToRemove.add(key);
				}
			}

			for (String key : orderItemKeysToRemove) {
				orderItemKeyMap.remove(key);
			}
		} else {
			for (String key : orderItemKeyMap.keySet()) {
				Decimal quantity = 0;
				Schedule__c schedule;
				for (ScheduleWrapper wrapper : orderItemKeyMap.get(key)) {
					schedule = wrapper.schedule;
					quantity += countCollections(schedule.Start_Date__c, schedule.End_Date__c, schedule.Suspension_Start_Date__c, schedule.Reactivation_Start_Date__c, schedule.Days__c, schedule.Fortnightly__c, schedule.Week_Off__c, schedule.Collection_Quantity__c);
				}
				orderItemCollectionCountMap.put(key, quantity.intValue());
			}
		}
	}

	private Integer countCollections(Date startDate, Date endDate, Date suspensionStartDate, Date reactivationStartDate, String weekDay, Boolean isFortnightly, Boolean isWeekOff, Decimal quantity) {
		Integer collectionDayCount = 0;
		Date suspensionEndDate;
		startDate = startDate == null || startDate < TODAY ? TODAY : startDate;
		endDate = endDate == null || endDate > QUATER_END ? QUATER_END : endDate;
		if (suspensionStartDate != null && reactivationStartDate != null && suspensionStartDate <= endDate && reactivationStartDate > startDate) {
			suspensionStartDate = suspensionStartDate < startDate ? startDate : suspensionStartDate;
			suspensionEndDate = reactivationStartDate > endDate ? endDate : reactivationStartDate?.addDays(-1);
		}
		collectionDayCount = DateUtil.countDays(startDate, endDate, weekDay, suspensionStartDate, suspensionEndDate);
		if (isFortnightly) {
			Integer fortnightlyDays = collectionDayCount / 2;
			if (Math.mod(collectionDayCount, 2) != 0) {
				if (DateUtil.Day.valueOf(weekDay).ordinal() < DateUtil.getDayOfWeek(startDate).ordinal()) {
					isWeekOff = !isWeekOff;
				}
				fortnightlyDays = isWeekOff ? ++fortnightlyDays : fortnightlyDays;
			}
			collectionDayCount = fortnightlyDays;
		}
		return collectionDayCount * quantity.intValue();
	}

	private void insertOrders() {
		Schedule__c schedule;
		String orderKey;
		for (String productKey : orderItemKeyMap.keySet()) {
			schedule = orderItemKeyMap.get(productKey)[0].schedule;
			orderKey = getUniqueOrderKey(schedule);
			if (!orderMap.containsKey(orderKey)) {
				Order order = OrderUtil.createOrder(schedule);
				order.PeriodStart__c = DateUtil.getQuarterStartDate(TODAY);
				order.PeriodEnd__c = QUATER_END;
				orderMap.put(orderKey, order);
			}
		}

		Database.SaveResult[] results = Database.insert(orderMap.values(), false);
		LogRegister.createLogsUpsert(results, orderMap.values(), 'Advance Bin Collection Orders', 'Insert', 'Order', 'AccountId');
	}

	private void insertOrderItems() {
		List<OrderItem> orderItems = new List<OrderItem>();
		Schedule__c schedule;
		Order order;
		for (String productKey : orderItemKeyMap.keySet()) {
			schedule = orderItemKeyMap.get(productKey)[0].schedule;
			order = orderMap.get(getUniqueOrderKey(schedule));

			Account_Discount__c discount;
			if (schedule.Discount_Type__c == 'Partner') {
				discount = partnerDiscounts.get(schedule.Location__r.Partnership__c + '-' + schedule.Supplier_Product__r.Product__c);
			} else if (schedule.Discount_Type__c == 'Account') {
				discount = accountDiscounts.get(schedule.Location__r.ParentId + '-' + schedule.Supplier_Product__r.Product__c);
			}

			orderItems.add(OrderUtil.createOrderItem(order, schedule, orderItemCollectionCountMap.get(productKey), discount));
		}

		Database.SaveResult[] results1 = Database.insert(orderItems, false);
		LogRegister.createLogsUpsert(results1, orderItems, 'OrderItems added to Advance Bin Collection Orders', 'Insert', 'OrderItem', 'OrderId');

		OrderUtil.setBinOrderAsConfirmed(orderMap.values());
		Database.SaveResult[] results2 = Database.update(orderMap.values(), false);
		LogRegister.createLogsUpsert(results2, orderMap.values(), 'Set Advance Bin Collection Orders to Confirmed status', 'Update', 'Order', 'AccountId');
	}

	public void finish(Database.BatchableContext batchContext) {}

	private class ScheduleWrapper {
		private Schedule__c schedule {
			get {
				return schedule != null ? schedule : history.Schedule__r;
			}
			set;
		}

		private ScheduleAdvanceInvoiceHistory__c history { get; set;}

		private ScheduleWrapper(Schedule__c schedule) {
			this.schedule = schedule;
		}

		private ScheduleWrapper(ScheduleAdvanceInvoiceHistory__c history) {
			this.history = history;
		}
	}
}