@isTest
private class DeleteDeliveryPackageSchedularTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock());
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		DeliveryPackage__c pkg = TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_CANCELLED);
		Test.setCreatedDate(pkg.Id, Datetime.now().addDays(-61));
	}

	@isTest
	static void deletePackages() {
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c LIMIT 1];
		Test.startTest();
		new DeleteDeliveryPackageSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM DeliveryPackage__c].size());
	}

	@isTest
	static void deleteTrackingFiles() {
		DeliveryPackageTrackingFile__c trackingFile = new DeliveryPackageTrackingFile__c(FileName__c = 'SampleFile.csv');
		INSERT trackingFile;

		Test.setCreatedDate(trackingFile.Id, Datetime.now().addDays(-35));
		Test.startTest();
		new DeleteDeliveryPackageSchedular().execute(null);
		Test.stopTest();
		Assert.areEqual(0, [SELECT Id FROM DeliveryPackageTrackingFile__c].size());
	}
}