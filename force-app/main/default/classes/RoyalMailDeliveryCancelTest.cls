@isTest
private class RoyalMailDeliveryCancelTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertSupplierFirstMile();
		Order order = TestDataHelper.insertOrder(location.Id);
		Product2 product = TestDataHelper.insertProduct('Test Name', 'Test Code', 'Delivery');
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
		TestDataHelper.insertOrderItem(order.Id, product.Id, pbe.Id);
		TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_LABELLED, DeliveryPackage.CARRIER_ROYAL_MAIL);
	}

	@isTest
	static void sendRequest() {
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c];
		pkg.Status__c = DeliveryPackage.STATUS_CANCEL_REQUEST;

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		UPDATE pkg;
		Test.stopTest();

		pkg = [SELECT Status__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_CANCELLED, pkg.Status__c);
	}

	@isTest
	static void sendShipmentErrorRequest() {
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c];
		pkg.Status__c = DeliveryPackage.STATUS_CANCEL_REQUEST;

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		UPDATE pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, Message__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_CANCEL_REQUEST, pkg.Status__c);
		Assert.isNotNull(pkg.Message__c);
	}

	private class Mock implements HttpCalloutMock {

		Boolean isError = false;

		private Mock() {}

		private Mock(Boolean isError) {
			this.isError = isError;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse response = new HTTPResponse();
			RoyalMailDelivery.CancelResponse cancelResponse = new RoyalMailDelivery.CancelResponse();

			if (isError) {
				cancelResponse.Errors = new List<RoyalMailDelivery.Error>{new RoyalMailDelivery.Error()};
				cancelResponse.Errors[0].Message = 'Random error message';
				response.setStatusCode(400);
			} else {
				response.setStatusCode(200);
			}

			response.setBody(JSON.serialize(cancelResponse));
			return response;
		}
	}	
}