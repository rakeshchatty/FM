public without sharing class OrderUtil {

	public static final String STATUS_INVOICED = 'Invoiced';
	public static final String STATUS_CANCELLED = 'Cancelled';

	public static Boolean isCredit(Order order) {
		return order.Original_Invoice_to_Credit__c != null;
	}

	public static Boolean needsPartnerLine(Order order) {
		return order.Partner_Total_Amount__c != null;
	}

	/**
	 * Get the invoice frequency based on the order
	 * @param accountToInvoice could be partner, parent or location
	 */
	public static String getInvoiceFrequency(Order order, Account accountToInvoice) {
		if (isCredit(order)) {
			return Invoicing.FREQUENCY_IMMEDIATE;
		}

		if (AccountUtil.isPartner(accountToInvoice)) {
			return accountToInvoice.InvoiceFrequency__c;
		}

		if (isAdvanceBinOrder(order)) {
			return Invoicing.FREQUENCY_QUARTERLY_ADVANCE;
		}

		String locationFrequency = order.Account.EffectiveInvoiceFrequency__c;
		if (locationFrequency == Invoicing.FREQUENCY_MONTHLY_SCHEDULED || locationFrequency == Invoicing.FREQUENCY_MONTHLY_SEPARATED) {
			return isScheduled(order) ? Invoicing.FREQUENCY_MONTHLY_SCHEDULED :
				locationFrequency == Invoicing.FREQUENCY_MONTHLY_SCHEDULED ? Invoicing.FREQUENCY_IMMEDIATE : Invoicing.FREQUENCY_MONTHLY;
		}

		return locationFrequency;
	}

	public static Boolean skipInvoice(Order order) {
		return !isCredit(order) && !AccountUtil.isLive(order.Account);
	}

	private static Boolean isBin(Order order) {
		return order.Is_wheelie_bin_order__c;
	}

	public static Boolean isScheduled(Order order) {
		return isBin(order) || order.Recurring__c;
	}

	public static Boolean isAdvanceBinOrder(Order order) {
		return isBin(order) && order.Account.Parent.IsBinCollectionAdvanceInvoiced__c;
	}

	public static Boolean isFrequencyOverridden(Order order) {
		return !isAdvanceBinOrder(order) && AccountUtil.isFrequencyOverridden(order.Account);
	}

	public static Order createOrder(Schedule__c schedule) {
		return createOrder(schedule.Location__c, schedule.Supplier__r, System.today(), schedule.Po_Number__c);
	}

	public static Order createOrder(Collection_Waypoints__c collectionWaypoint) {
		return createOrder(collectionWaypoint.Location__c, collectionWaypoint.Supplier__r, collectionWaypoint.Daily_Dispatch__r.CreatedDate.date(), collectionWaypoint.Collection_Schedule__r.Po_Number__c);
	}

	private static Order createOrder(Id locationId, Suppliers__c supplier, Date deliveryDate, String poNumber) {
		String supplierStatus = (String.isBlank(supplier?.Name) || supplier?.Name == 'First Mile Ltd') ? '' : 'Accepted';
		return new Order(AccountId = locationId, Supplier__c = supplier?.Id, Supplier_Status__c = supplierStatus,
						EffectiveDate = deliveryDate, Requested_Delivery_Date__c = deliveryDate,
						Status = 'Draft', IsBinCollection__c = true, ConfirmationEmailStatus__c = 'Do Not Send',
						PO_Number__c = String.isNotBlank(poNumber) ? poNumber : null);
	}

	public static OrderItem createOrderItem(Order order, Schedule__c schedule, Decimal quantity, Account_Discount__c discount) {
		return createOrderItem(order.Id, schedule.Supplier_Product__r.Product__c, schedule.Location__r.Price_Book__c,
			schedule.Supplier__c, quantity, schedule.Enqix_Price__c,
			schedule.Discount_Type__c, discount);
	}

	public static OrderItem createOrderItem(Order order, Collection_Waypoints__c collectionWaypoint) {
		OrderItem orderItem = createOrderItem(order.Id, collectionWaypoint.Supplier_Product__r.Product__c, collectionWaypoint.Location__r.Price_Book__c,
			collectionWaypoint.Supplier__c, collectionWaypoint.Collection_Quantity__c, collectionWaypoint.Manual_Price__c,
			collectionWaypoint.Discount_Type__c, collectionWaypoint.Account_Discount__r);
		orderItem.Collection_Waypoint__c = collectionWaypoint.Id;
		return orderItem;
	}

	private static OrderItem createOrderItem(Id orderId, Id productId, Id pricebookId, Id supplierId, Decimal quantity, Decimal listPrice, String discountType, Account_Discount__c discount) {
		OrderItem orderItem = new OrderItem(OrderId = orderId, Product2Id = productId, Price_Book__c = pricebookId, Supplier__c = supplierId,
					Quantity = quantity, Discount_to_Apply__c = 'Account');

		if (listPrice != null) {
			orderItem.ListPrice__c = listPrice;
		}

		if (discount == null) {
			return orderItem;
		}

		if (discount.Product_Discount__c == null) {
			discount.Product_Discount__c = 0; // Null will cause error, reset to 0
		}

		if (discountType == 'Partner') {
			orderItem.Discount_to_Apply__c = 'Partner';
			orderItem.Account_Discount__c = discount.Id;
			orderItem.Partner_Discount__c = discount.Product_Discount__c;
			if (discount.BID_Price__c != null) {
				orderItem.Partner_Discount__c += discount.BID_Price__c;
			}
		} else if (discountType == 'Account') {
			orderItem.Account_Discount__c = discount.Id;
			orderItem.Discount__c = discount.Product_Discount__c;
		}
		return orderItem;
	}

	public static void setBinOrderAsConfirmed(List<Order> orders) {
		for (Order order : orders) {
			order.Type = 'Contractor';
			order.Status = 'Confirmed';
			order.Delivery_Status__c = 'Invoiced';
		}
	}
}