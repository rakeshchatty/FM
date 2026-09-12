public without sharing class Vat {

	public static final Decimal DEFAULT_VAT_RATE = 20;

	public static Decimal calculate(List<OrderController.OrderItemData> orderItems) {
		Map<Decimal, Decimal> vatRateToAmountMap = new Map<Decimal, Decimal>();
		for (OrderController.OrderItemData item : orderItems) {
			if (!vatRateToAmountMap.containsKey(item.vatRate)) {
				vatRateToAmountMap.put(item.vatRate, 0);
			}
			vatRateToAmountMap.put(item.vatRate, vatRateToAmountMap.get(item.vatRate) + item.totalPrice);
		}

		Decimal vat = 0;
		for (Decimal vatRate : vatRateToAmountMap.keySet()) {
			vat += vatRateToAmountMap.get(vatRate) * vatRate / 100;
		}

		return vat.setScale(2, RoundingMode.HALF_UP);
	}

	public static void calculate(Set<Id> orderIds) {
		if (orderIds.isEmpty()) {
			return;
		}

		List<Order> orders = [SELECT Id, Account.RecordTypeId, (SELECT TotalPrice, VATRate__c, PartnerVATRate__c FROM OrderItems) FROM Order WHERE Id IN :orderIds AND Status != 'Invoiced'];
		Map<Id, Map<Decimal, Decimal>> orderMap = new Map<Id, Map<Decimal, Decimal>>();
		for (Order order : orders) {
			Boolean isPartnerOrder = order.Account.RecordTypeId == AccountUtil.RECORDTYPEID_PARTNER;
			Map<Decimal, Decimal> vatRateToAmountMap = new Map<Decimal, Decimal>();
			orderMap.put(order.Id, vatRateToAmountMap);
			for (OrderItem item : order.OrderItems) {
				Decimal vatRate = isPartnerOrder ? item.PartnerVATRate__c : item.VATRate__c;
				if (!vatRateToAmountMap.containsKey(vatRate)) {
					vatRateToAmountMap.put(vatRate, 0);
				}
				vatRateToAmountMap.put(vatRate, vatRateToAmountMap.get(vatRate) + item.TotalPrice);
			}
		}

		List<Order> ordersToUpdate = new List<Order>();
		for (Id orderId : orderMap.keySet()) {
			Map<Decimal, Decimal> vatRateToAmountMap = orderMap.get(orderId);
			Decimal orderVat = 0;
			for (Decimal vatRate : vatRateToAmountMap.keySet()) {
				orderVat += vatRateToAmountMap.get(vatRate) * vatRate / 100;
			}
			orderVat = orderVat.setScale(2, RoundingMode.HALF_UP);

			ordersToUpdate.add(new Order(Id = orderId, VAT__c = orderVat));
		}

		if (!ordersToUpdate.isEmpty()) {
			Database.SaveResult[] results = Database.update(ordersToUpdate, false);
			LogRegister.createLogsUpsert(results, ordersToUpdate, 'Set VAT on Order', 'Update', 'Order', null);
		}
	}

	public static Decimal calculate(Invoice_Header__c invoice) {
		Map<Decimal, Decimal> vatRateToAmountMap = new Map<Decimal, Decimal>();
		for (Invoice_Line__c line : invoice.Invoice_Lines__r) {
			if (!vatRateToAmountMap.containsKey(line.VATRate__c)) {
				vatRateToAmountMap.put(line.VATRate__c, 0);
			}
			vatRateToAmountMap.put(line.VATRate__c, vatRateToAmountMap.get(line.VATRate__c) + line.Amount__c);
		}

		Decimal vat = 0;
		for (Decimal vatRate : vatRateToAmountMap.keySet()) {
			vat += vatRateToAmountMap.get(vatRate) * vatRate / 100;
		}

		return vat.setScale(2, RoundingMode.HALF_UP);
	}
}