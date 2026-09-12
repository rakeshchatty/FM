@isTest
private class DeliveryPackageShipmentBatchTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertSupplier('First Mile Ltd');
		TestDataHelper.insertOrder(location.Id);
	}

	@isTest
	static void sendRequest() {
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = Date.Today());

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock());
		Test.startTest();
		INSERT pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, TrackingId__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_LABELLED, pkg.Status__c);
		Assert.areEqual('12345678', pkg.TrackingId__c);

		Attachment attachment = [SELECT Id FROM Attachment WHERE ParentId = :pkg.Id AND Name LIKE 'Parcelforce Label - %.pdf'];
		Assert.isNotNull(attachment);
	}

	@isTest
	static void sendShipmentErrorRequest() {
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = Date.Today());

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentErrorMock());
		Test.startTest();
		INSERT pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, TrackingId__c, Message__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_ERROR, pkg.Status__c);
		Assert.isNull(pkg.TrackingId__c);
		Assert.isNotNull(pkg.Message__c);

		try {
			Attachment attachment = [SELECT Id FROM Attachment WHERE ParentId = :pkg.Id AND Name LIKE 'Parcelforce Label - %.pdf'];
			Assert.fail();
		} catch (QueryException e) {}
	}

	@isTest
	static void labelErrorRequest() {
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = Date.Today());

		Test.setMock(WebServiceMock.class, new ParcelforceSoap.LabelErrorMock());
		Test.startTest();
		INSERT pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, TrackingId__c, Message__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_ERROR, pkg.Status__c);
		Assert.isNotNull(pkg.TrackingId__c);
		Assert.isNotNull(pkg.Message__c);

		try {
			Attachment attachment = [SELECT Id FROM Attachment WHERE ParentId = :pkg.Id AND Name LIKE 'Parcelforce Label - %.pdf'];
			Assert.fail();
		} catch (QueryException e) {}
	}
}