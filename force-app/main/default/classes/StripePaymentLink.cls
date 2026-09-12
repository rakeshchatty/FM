public without sharing class StripePaymentLink {

	@InvocableMethod
	public static void get(List<Id> orderIds) {
		for (Id orderId : orderIds) {
			get(orderId);
		}
	}

	@future(callout=true)
	private static void get(Id orderId) {
		Order order = [SELECT OrderNumber, PaymentUrl__c, Order_Amount_inc_VAT__c, CurrencyIsoCode FROM Order WHERE Id = :orderId];

		if (!String.isBlank(order.PaymentUrl__c)) {
			return;
		}
		
		String body =
			'line_items[0][quantity]=1' +
			'&line_items[0][price_data][currency]=' + order.CurrencyIsoCode +
			'&line_items[0][price_data][unit_amount]=' + Integer.valueOf(order.Order_Amount_inc_VAT__c * 100) +
			'&line_items[0][price_data][product_data][name]=' + EncodingUtil.urlEncode('Order:' + order.OrderNumber, 'UTF-8') +
			'&metadata[payment_type]=Credit Card' +
			'&metadata[salesforce_order_id]=' + EncodingUtil.urlEncode(order.Id, 'UTF-8');

		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:Stripe/payment_links');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/x-www-form-urlencoded');
		request.setBody(body);

		HttpResponse response = new Http().send(request);

		if (response.getStatusCode() != 200) {
			UPDATE new Order(Id = order.Id, PaymentStatus__c = 'Link Failed');
			return;
		}

		Map<String, Object> responseBody = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
		String url = (String)responseBody.get('url');
		if (String.isBlank(url)) {
			UPDATE new Order(Id = order.Id, PaymentStatus__c = 'Link Failed');
			return;
		}

		List<Order> orders = new List<Order>{new Order(Id = order.Id, PaymentUrl__c = url, PaymentStatus__c = 'Pending')};
		Database.SaveResult[] results = Database.update(orders, false);
		LogRegister.createLogsUpsert(results, orders, 'Order update with Stripe Payment Link', 'Update', 'Order', 'AccountId');
	}
}