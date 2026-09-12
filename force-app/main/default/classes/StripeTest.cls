@isTest
public without sharing class StripeTest {
	@testSetup
	static void setup() {
		Product2 product = TestDataHelper.insertProduct('Product 1','P0001', 'Delivery');
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		PricebookEntry pricebookEntry = TestDataHelper.insertStandardPricebookEntry(product.Id, 50);

		Order order = TestDataHelper.insertOrder(location.Id);
		TestDataHelper.insertOrderItem(order.Id, product.Id, pricebookEntry.Id);
	}

	@isTest static void getPaymentUrl() {
		Order order = [SELECT Id FROM Order];

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		StripePaymentLink.get(new List<Id>{order.Id});
		Test.stopTest();
	}

	@isTest static void getPaymentUrlError() {
		Order order = [SELECT Id FROM Order];

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		StripePaymentLink.get(new List<Id>{order.Id});
		Test.stopTest();
	}

	@isTest static void setPaymentStatus() {
		Order order = [SELECT Id FROM Order];

		Map<String, Object> metadata = new Map<String, Object>{'salesforce_order_id' => order.Id};
		Map<String, Object> stripeObj = new Map<String, Object>{'metadata' => metadata, 'payment_intent' => 'pi_123456789'};
		Map<String, Object> dataMap = new Map<String, Object>{'object' => stripeObj};
		Map<String, Object> payload = new Map<String, Object>{'type' => 'checkout.session.completed', 'data' => dataMap};

		RestRequest request = new RestRequest();
		request.addHeader('httpMethod', 'POST');
		request.requestUri = '/services/apexrest/stripewebhook/';
		request.requestBody = Blob.valueOf(JSON.serialize(payload));

		RestResponse response = new RestResponse();
		RestContext.request = request;
		RestContext.response = response;

		Test.startTest();
		StripeWebhook.post();
		Test.stopTest();
	}

	private class Mock implements HttpCalloutMock {

		Boolean isError = false;

		private Mock() {}

		private Mock(Boolean isError) {
			this.isError = isError;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			if (isError) {
				res.setStatusCode(400);
			} else {
				res.setStatusCode(200);
				res.setBody(Json.serialize(new Map<String, Object>{'url' => 'https://buy.stripe.com/test_eVq28s82kc5R41l71v0Fi10'}));
			}
			return res;
		}
	}
}