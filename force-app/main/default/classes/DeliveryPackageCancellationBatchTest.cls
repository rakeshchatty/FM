@isTest
private class DeliveryPackageCancellationBatchTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertSupplier('First Mile Ltd');
		Order order = TestDataHelper.insertOrder(location.Id);
		Product2 product = TestDataHelper.insertProduct('Test Name', 'Test Code', 'Delivery');
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
		TestDataHelper.insertOrderItem(order.Id, product.Id, pbe.Id);
		TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_LABELLED);
	}

	@isTest
	static void sendRequest() {
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c];
		pkg.Status__c = DeliveryPackage.STATUS_CANCEL_REQUEST;

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.CancellationSuccessMock());
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

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.CancellationErrorMock());
		Test.startTest();
		UPDATE pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, Message__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_CANCELLED, pkg.Status__c);
		Assert.isNotNull(pkg.Message__c);
	}
}