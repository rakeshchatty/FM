@RestResource(urlMapping='/stripewebhook/*')
global without sharing class StripeWebhook {

	@HttpPost
	global static void post() {
		RestContext.response.statusCode = 200;

		String orderId;
		String paymentReference;
		try {
			Map<String, Object> payload = (Map<String, Object>)JSON.deserializeUntyped(RestContext.request.requestBody.toString());

			// We ONLY act on checkout.session.completed
			if ((String)payload.get('type') != 'checkout.session.completed') {
				return;
			}

			Map<String, Object> dataMap = (Map<String, Object>)payload.get('data');
			Map<String, Object> stripeObj = (Map<String, Object>)dataMap.get('object');
			Map<String, Object> metadata = (Map<String, Object>)stripeObj.get('metadata');

			orderId = (String)metadata.get('salesforce_order_id');
			if (String.isBlank(orderId)) {
				return;
			}

			paymentReference = (String)stripeObj.get('payment_intent');
		} catch (Exception e) {}

		List<Order> orders = new List<Order>{new Order(Id = orderId, PaymentStatus__c = 'Paid', PaymentReference__c = paymentReference)};
		Database.SaveResult[] results = Database.update(orders, false);
		LogRegister.createLogsUpsert(results, orders, 'Order update from StripeWebhook', 'Update', 'Order', 'AccountId');
	}
}