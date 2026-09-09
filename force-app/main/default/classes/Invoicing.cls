public without sharing class Invoicing {

	public static final String FREQUENCY_IMMEDIATE = 'Per Order';
	public static final String FREQUENCY_WEEKLY = 'Weekly';
	public static final String FREQUENCY_TWICEMONTHLY = 'Twice Monthly';
	public static final String FREQUENCY_MONTHLY = 'Monthly';
	public static final String FREQUENCY_QUARTERLY_ADVANCE = 'Quarterly - Advance';
	public static final String FREQUENCY_MONTHLY_SCHEDULED = 'Monthly - Scheduled';
	public static final String FREQUENCY_MONTHLY_SEPARATED = 'Monthly - Separated';

	public static final String STATUS_OPEN = 'Draft';
	public static final String STATUS_CLOSED = 'Invoiced';

	public static Boolean BOOL_TEST_FUTURE = false;

	/**
	 * For each order, create new invoice or add invoice lines to an existing draft perodic invoice.
	 * Separate invoices are created for the location and partner.
	 * Credit note order and immediate frequency order will always create new invoice.
	 * Periodic invoice frequency location will create new invoice only if an existing draft periodic invoice cannot be found.
	 */
	public static void convert(List<Order> orders) {
		Set<Id> orderIds = new Set<Id>();
		Set<Id> partnerOrderIds = new Set<Id>();
		for (Order order : orders) {
			orderIds.add(order.Id);
			if (!OrderUtil.isCredit(order) && OrderUtil.needsPartnerLine(order)) {
				partnerOrderIds.add(order.Id);
			}
		}

		if (System.isFuture() || System.isBatch() || BOOL_TEST_FUTURE) {
			convertWheeliesAndRecurrings(orderIds);
		} else {
			convert(orderIds);
		}

		if (!partnerOrderIds.isEmpty()) {
			if (System.isFuture() || System.isBatch() || BOOL_TEST_FUTURE) {
				convertPartnerWheeliesAndRecurrings(partnerOrderIds);
			} else {
				convertPartner(partnerOrderIds);
			}
		}
	}

	// Add invoice lines for the order items, to a newly INSERT-ed invoice.
	// Since the input list of invoices is from AFTER INSERT, they cannot be updated.
	public static void createLines(List<Invoice_Header__c> invoicesReadOnly) {
		List<Invoice_Header__c> invoices = new List<Invoice_Header__c>();
		Map<Id, Invoice_Header__c> orderToInvoiceMap = new Map<Id, Invoice_Header__c>();

		for (Invoice_Header__c invoiceReadOnly : invoicesReadOnly) {
			for (String orderId : split(invoiceReadOnly.OrderIds__c)) {
				orderToInvoiceMap.put(orderId, invoiceReadOnly);
			}
		}
		Map<ID, Order> orderMap = getOrder(orderToInvoiceMap.keySet());

		for (Invoice_Header__c invoiceReadOnly : invoicesReadOnly) {
			if (!invoiceReadOnly.Salesforce__c) {
				continue;
			}

			for (String orderId : split(invoiceReadOnly.OrderIds__c)) {
				orderToInvoiceMap.put(orderId, invoiceReadOnly);
			}

			Invoice_Header__c invoice = new Invoice_Header__c(Id = invoiceReadOnly.Id);
			//Bruno 07.01.2019 - JIRA 1223 - InvoiceNo__c field needed because of CP
			invoice.InvoiceNo__c = invoiceReadOnly.InvoiceNo2__c;
			invoice.AmountExclVAT__c = 0;
			invoice.VAT__c = 0;

			if (invoiceReadOnly.InvoiceFrequency__c == FREQUENCY_IMMEDIATE) {
				invoice.Status__c = STATUS_CLOSED;
			}
			invoices.add(invoice);
		}

		Map<Id, List<OrderItem>> orderItems = getOrderItems(orderToInvoiceMap.keySet());

		List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();
		for (Id orderId : orderItems.keySet()) {
			newInvoiceLines.addAll(createLines(orderToInvoiceMap.get(orderId), orderItems.get(orderId), orderMap.get(orderId)));
		}

		Database.SaveResult[] sr1 = Database.insert(newInvoiceLines, false);
		LogRegister.createLogsUpsert(sr1, newInvoiceLines, 'Lines added on newly created invoices', 'Insert', 'Invoice_Line__c', 'Invoice_HeaderId__c');

		Database.SaveResult[] sr2 = Database.update(invoices, false);
		LogRegister.createLogsUpsert(sr2, invoices, 'Set default values on newly created invoices', 'Update', 'Invoice_Header__c', null);
	}

	@future
	private static void convert(Set<Id> orderIds) {
		convertWheeliesAndRecurrings(orderIds);
	}

	private static void convertWheeliesAndRecurrings(Set<Id> orderIds) {
		Map<ID, Order> orderMap = getOrder(orderIds);
		Map<Id, List<OrderItem>> orderItemsMap = getOrderItems(orderIds);

		Set<Id> parentIds = new Set<Id>();
		Set<Id> locationIds = new Set<Id>();
		for (Order order : orderMap.values()) {
			if (isImmediate(OrderUtil.getInvoiceFrequency(order, order.Account))) { // No need to fetch existing draft invoices, as these are to be created as new invoices
				continue;
			}

			if (OrderUtil.isFrequencyOverridden(order)) {
				locationIds.add(order.AccountId);
			} else {
				parentIds.add(order.Account.ParentId);
			}
		}

		Map<Id, Invoice_Header__c> locationInvoices = new Map<Id, Invoice_Header__c>();
		Map<Id, Invoice_Header__c> scheduledInvoices = new Map<Id, Invoice_Header__c>();
		for (Invoice_Header__c invoice : [SELECT IsPartnerHeader__c, Account__c, Location__r.ParentId, Location__c, Original_Invoice_to_Credit__c, InvoiceFrequency__c FROM Invoice_Header__c
			WHERE Location__c IN :locationIds AND Salesforce__c = true AND Status__c = :STATUS_OPEN AND IsPartnerHeader__c = false]) {
			if (invoice.Account__c == invoice.Location__r.ParentId) {   // Fix to ensure re-parenting creates a new location invoice
				if (invoice.InvoiceFrequency__c == FREQUENCY_MONTHLY_SCHEDULED) {
					scheduledInvoices.put(invoice.Location__c, invoice);
				} else {
					locationInvoices.put(invoice.Location__c, invoice);
				}
			}
		}

		Map<Id, Invoice_Header__c> parentInvoices = new Map<Id, Invoice_Header__c>();
		for (Invoice_Header__c invoice : [SELECT IsPartnerHeader__c, Account__c, Original_Invoice_to_Credit__c, InvoiceFrequency__c FROM Invoice_Header__c
			WHERE Account__c IN :parentIds AND Location__c = null AND Salesforce__c = true AND Status__c = :STATUS_OPEN AND InvoiceFrequency__c != :FREQUENCY_QUARTERLY_ADVANCE AND IsPartnerHeader__c = false]) {
			if (invoice.InvoiceFrequency__c == FREQUENCY_MONTHLY_SCHEDULED) {
				scheduledInvoices.put(invoice.Account__c, invoice);
			} else {
				parentInvoices.put(invoice.Account__c, invoice);
			}
		}

		Map<Id, Invoice_Header__c> advanceInvoices = new Map<Id, Invoice_Header__c>();
		for (Invoice_Header__c invoice : [SELECT IsPartnerHeader__c, Account__c, Original_Invoice_to_Credit__c FROM Invoice_Header__c
			WHERE Account__c IN :parentIds AND Location__c = null AND Salesforce__c = true AND Status__c = :STATUS_OPEN AND InvoiceFrequency__c = :FREQUENCY_QUARTERLY_ADVANCE AND IsPartnerHeader__c = false]) {
				advanceInvoices.put(invoice.Account__c, invoice);
		}

		List<Invoice_Header__c> newInvoices = new List<Invoice_Header__c>();
		List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();
		Map<Id, Invoice_Header__c> newPeriodicInvoices = new Map<Id, Invoice_Header__c>();

		Map<Id, Invoice_Header__c> existingInvoices;
		Id accountId;
		for (Order order : orderMap.values()) {
			if (OrderUtil.skipInvoice(order)) {
				continue;
			}

			String orderInvoiceFrequency = OrderUtil.getInvoiceFrequency(order, order.Account);
			if (isImmediate(orderInvoiceFrequency)) {
				// This covers immediate frequency, credit note as well as partner credit note
				// Order.Account would be a 'location' usually, and 'partner' only when order is a partner credit note
				Boolean isPartner = AccountUtil.isPartner(order.Account);
				newInvoices.add(create(order, isPartner ? order.Account : order.Account.Parent, isPartner));
				continue;
			}

			if (OrderUtil.isAdvanceBinOrder(order)) {
				existingInvoices = advanceInvoices;
				accountId = order.Account.ParentId;
			} else if (OrderUtil.isScheduled(order) && orderInvoiceFrequency == Invoicing.FREQUENCY_MONTHLY_SCHEDULED) {
				existingInvoices = scheduledInvoices;
				accountId = OrderUtil.isFrequencyOverridden(order) ? order.AccountId : order.Account.ParentId;
			} else if (OrderUtil.isFrequencyOverridden(order)) {
				existingInvoices = locationInvoices;
				accountId = order.AccountId;
			} else {
				existingInvoices = parentInvoices;
				accountId = order.Account.ParentId;
			}

			if (existingInvoices.containsKey(accountId)) {
				newInvoiceLines.addAll(createLines(existingInvoices.get(accountId), orderItemsMap.get(order.Id), order));
			} else {
				if (newPeriodicInvoices.containsKey(accountId)) {
					appendOrder(newPeriodicInvoices.get(accountId), order);
				} else {
					Invoice_Header__c invoice = create(order, order.Account.Parent, false);
					newInvoices.add(invoice);
					newPeriodicInvoices.put(accountId, invoice);
				}
			}
		}

		if (!newInvoices.isEmpty()) {
			Database.SaveResult[] sr = Database.insert(newInvoices, false);
			LogRegister.createLogsUpsert(sr, newInvoices, 'New invoices created', 'Insert', 'Invoice_Header__c', 'Account__c');
		}

		if (!newInvoiceLines.isEmpty()) {
			Database.SaveResult[] sr = Database.insert(newInvoiceLines, false);
			LogRegister.createLogsUpsert(sr, newInvoiceLines, 'Lines added to existing invoices', 'Insert', 'Invoice_Line__c', 'Invoice_HeaderId__c');
		}
	}

	@future
	private static void convertPartner(Set<Id> orderIds) {
		convertPartnerWheeliesAndRecurrings(orderIds);
	}

	private static void convertPartnerWheeliesAndRecurrings(Set<Id> orderIds) {
		//Get Partner Accounts
		Map<ID, Order> orderMap = getOrder(orderIds);
		Map<Id, List<OrderItem>> orderItemsMap = getOrderItems(orderIds);

		//TODO - check if the Account-Partnership from the Order comes null or not, it should not come null because all orders that enter here
		//have the Partner_Total_Amount != null so that means that it has a partnership
		Set<Id> partnerAccountIds = new Set<Id>();
		for (Order order : orderMap.values()) {
			partnerAccountIds.add(order.Account.Partnership__c);
		}

		Map<Id, Invoice_Header__c> existingInvoices = new Map<Id, Invoice_Header__c>();
		for (Invoice_Header__c invoice : [SELECT IsPartnerHeader__c, Account__c, Original_Invoice_to_Credit__c FROM Invoice_Header__c
			WHERE Account__c IN :partnerAccountIds AND Salesforce__c = true AND Status__c = :STATUS_OPEN AND IsPartnerHeader__c = true]) {
				existingInvoices.put(invoice.Account__c, invoice);
		}

		Map<Id, Invoice_Header__c> newPeriodicInvoices = new Map<Id, Invoice_Header__c>();
		List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();
		for (Order order : orderMap.values()) {
			if (OrderUtil.skipInvoice(order)) {
				continue;
			}

			if (existingInvoices.containsKey(order.Account.Partnership__c)) {
				newInvoiceLines.addAll(createLines(existingInvoices.get(order.Account.Partnership__c), orderItemsMap.get(order.Id), order));
			} else {
				if (newPeriodicInvoices.containsKey(order.Account.Partnership__c)) {
					appendOrder(newPeriodicInvoices.get(order.Account.Partnership__c), order);
				} else {
					newPeriodicInvoices.put(order.Account.Partnership__c, create(order, order.Account.Partnership__r, true));
				}
			}
		}

		if (!newPeriodicInvoices.isEmpty()) {
			Database.SaveResult[] sr = Database.insert(newPeriodicInvoices.values(), false);
			LogRegister.createLogsUpsert(sr, newPeriodicInvoices.values(), 'New partner invoices created', 'Insert', 'Invoice_Header__c', 'Account__c');
		}

		if (!newInvoiceLines.isEmpty()) {
			Database.SaveResult[] sr = Database.insert(newInvoiceLines, false);
			LogRegister.createLogsUpsert(sr, newInvoiceLines, 'Lines added to existing partner invoices', 'Insert', 'Invoice_Line__c', 'Invoice_HeaderId__c');
		}
	}

	private static Invoice_Header__c create(Order order, Account accountToInvoice, Boolean isPartnerInvoice) {
		Invoice_Header__c invoice = new Invoice_Header__c();
		invoice.CreatedDate__c = System.today();
		invoice.Status__c = STATUS_OPEN;
		invoice.Salesforce__c = true;
		invoice.OrderIds__c = order.Id;
		invoice.IsPartnerHeader__c = isPartnerInvoice;
		invoice.PeriodStart__c = order.PeriodStart__c;
		invoice.PeriodEnd__c = order.PeriodEnd__c;

		invoice.Original_Invoice_to_Credit__c = order.Original_Invoice_to_Credit__c;
		if (order.CreditCard_Payment__c) {
			invoice.Payment_Reference__c = order.PaymentReference__c;
		}

		invoice.InvoiceFrequency__c = OrderUtil.getInvoiceFrequency(order, accountToInvoice);
		invoice.DueDate__c = getDueDate(invoice.InvoiceFrequency__c);
		Boolean isImmediate = isImmediate(invoice.InvoiceFrequency__c);
		if (isImmediate) {
			invoice.OrderLookUp__c = order.Id;
		}

		invoice.Account__c = accountToInvoice.Id;
		if (isImmediate || isLocationInvoice(order, accountToInvoice)) {
			invoice.Location__c = AccountUtil.isPartner(accountToInvoice) ? null : order.AccountId;
			invoice.Account_Name__c = order.Account.Name;
		} else {
			invoice.Account_Name__c = accountToInvoice.Name;
		}

		return invoice;
	}

	// Add invoice lines for the order items, to an pre-existing invoice.
	private static List<Invoice_Line__c> createLines(Invoice_Header__c invoice, List<OrderItem> orderItems, Order order) {
		Boolean isPartner = invoice.IsPartnerHeader__c;
		Boolean isCredit = isCredit(invoice);

		List<Invoice_Line__c> newInvoiceLines = new List<Invoice_Line__c>();
		for (OrderItem orderItem : orderItems) {
			if (hasInvoiceLine(orderItem, isPartner)) {
				// If already invoiced, ignore.
				// This is useful when recovering from Order to Invoice failures by changing the Order status back from Delivered or Invoiced and then again back to Delivered.
				continue;
			}

			if (isPartner && !isCredit && orderItem.Partner_Unit_Price__c == null) {
				continue;
			}

			Invoice_Line__c invoiceLine = new Invoice_Line__c();
			invoiceLine.Invoice_HeaderId__c = invoice.Id;
			invoiceLine.Description__c = orderItem.Manual_Product_Name__c; //1 without manual product name
			invoiceLine.Qty__c = orderItem.Quantity; //2
			invoiceLine.Salesforce__c = true;
			invoiceLine.UnitPrice__c = (isPartner && isCredit) || !isPartner ? orderItem.UnitPrice : orderItem.Partner_Unit_Price__c; //3
			invoiceLine.Amount__c = orderItem.Quantity * invoiceLine.UnitPrice__c; //4
			invoiceLine.Order_Product__c = orderItem.Id;

			if (orderItem.Order.Account.VAT_Exempt__c) {
				invoiceLine.Vat__c = 0;
			} else {
				invoiceLine.Vat__c = (invoiceLine.Amount__c * TheVat__c.getInstance().Value__c).setScale(2, RoundingMode.HALF_UP); //5
			}

			invoiceLine.Product_Code__c = orderItem.Product2.ProductCode; //6
			//invoiceLine.DiscountWas__c = orderItem.ProductDiscount__c; //7
			invoiceLine.Location_Id__c = orderItem.Order.AccountId; //8
			invoiceLine.Product__c = orderItem.Product2Id; //9
			invoiceLine.Order__c = orderItem.OrderId; //10
			invoiceLine.Payment__c = order?.Bank_Statements__r[0]?.Id;

			newInvoiceLines.add(invoiceLine);
		}

		return newInvoiceLines;
	}

	private static Map<ID, Order> getOrder(Set<Id> orderIds) {
		return new Map<ID, Order>([SELECT CreditCard_Payment__c, PaymentReference__c, Original_Invoice_to_Credit__c, Is_wheelie_bin_order__c, Recurring__c,
			AccountId, Account.Name, Account.InvoiceFrequency__c, Account.RecordTypeId, Account.Enqix_Dead_Live__c, PeriodStart__c, PeriodEnd__c,
			Account.ParentId, Account.Parent.Name, Account.Parent.IsBinCollectionAdvanceInvoiced__c, Account.Parent.InvoiceFrequency__c, Account.Parent.RecordTypeId, Account.EffectiveInvoiceFrequency__c,
			Account.Partnership__c, Account.Partnership__r.Name, Account.Partnership__r.InvoiceFrequency__c, Account.Partnership__r.RecordTypeId,
			(SELECT Id FROM Bank_Statements__r LIMIT 1)
			FROM Order WHERE Id IN :orderIds]);
	}

	/**
	 * Prepare a map of order to its order items along with invoice lines of each order item.
	 */
	private static Map<Id, List<OrderItem>> getOrderItems(Set<Id> orderIds) {
		Map<Id, List<OrderItem>> orderToItemsMap = new Map<Id, List<OrderItem>>();
		List<OrderItem> orderItems = [SELECT OrderId, Quantity, UnitPrice, Product2.ProductCode, ProductDiscount__c, Product2Id, Partner_Unit_Price__c, Manual_Product_Name__c, Order.AccountId, Order.Account.VAT_Exempt__c,
			(SELECT Invoice_HeaderId__r.IsPartnerHeader__c FROM Invoice_Lines__r)
			FROM OrderItem WHERE OrderId IN :orderIds];

		for (OrderItem orderItem : orderItems) {
			if (orderToItemsMap.containsKey(orderItem.OrderId)) {
				orderToItemsMap.get(orderItem.OrderId).add(orderItem);
			} else {
				orderToItemsMap.put(orderItem.OrderId, new List<OrderItem>{orderItem});
			}
		}
		return orderToItemsMap;
	}

	private static void appendOrder(Invoice_Header__c invoice, Order order) {
		invoice.OrderIds__c += ',' + order.Id;
	}

	private static Boolean isLocationInvoice(Order order, Account accountToInvoice) {
		return !AccountUtil.isPartner(accountToInvoice) && OrderUtil.isFrequencyOverridden(order);
	}

	private static Boolean isImmediate(String frequency) {
		return frequency == FREQUENCY_IMMEDIATE;
	}

	public static Boolean isCredit(Invoice_Header__c invoice) {
		return invoice.Original_Invoice_to_Credit__c != null;
	}

	private static List<String> split(String commaSeparatedOrderIds) {
		if (String.isEmpty(commaSeparatedOrderIds)) {
			return new String[]{};
		}

		return commaSeparatedOrderIds.split(',');
	}

	private static Date getDueDate(String invoiceFrequency) {
		if (invoiceFrequency == FREQUENCY_IMMEDIATE || invoiceFrequency == FREQUENCY_QUARTERLY_ADVANCE) {
			return System.today();
		} else if (invoiceFrequency == FREQUENCY_WEEKLY) {
			return Duration.toNextSunday();
		} else if (invoiceFrequency == FREQUENCY_TWICEMONTHLY) {
			return Duration.toTwiceMonthlyEnd();
		} else if (invoiceFrequency == FREQUENCY_MONTHLY || invoiceFrequency == FREQUENCY_MONTHLY_SCHEDULED) {
			return Duration.toMonthEnd();
		} else {
			return null;
		}
	}

	/**
	 * Check if order item already has invoice line.
	 * @param isPartnerLine Check for presence of partner invoice line (true) or location invoice line (false).
	 */
	private static Boolean hasInvoiceLine(OrderItem orderItem, Boolean isPartnerLine) {
		if (orderItem.Invoice_Lines__r.isEmpty()) {
			return false;
		}

		for (Invoice_Line__c invoiceLine : orderItem.Invoice_Lines__r) {
			if (invoiceLine.Invoice_HeaderId__r.IsPartnerHeader__c == isPartnerLine) {
				return true;
			}
		}

		return false;
	}
}