@isTest
private class FirstMileDeliveryLabelTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertSupplier('First Mile Ltd');
		TestDataHelper.insertOrder(location.Id);
	}

	@isTest
	static void createLabel() {
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = Date.Today(), Carrier__c = DeliveryPackage.CARRIER_FIRST_MILE);

		Test.startTest();
		INSERT pkg;
		Test.stopTest();

		pkg = [SELECT Status__c, TrackingId__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_LABELLED, pkg.Status__c);
		Assert.isNull(pkg.TrackingId__c);

		Attachment attachment = [SELECT Id FROM Attachment WHERE ParentId = :pkg.Id];
		Assert.isNotNull(attachment);
	}
}