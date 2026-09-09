@isTest
public class DeliveryPackageTrackingEventHandlerTest {

	@testSetup
	static void testSetup() {
		TestDataHelper.insertVat();
		TestDataHelper.insertParcelforceSetting();
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Product2 product = TestDataHelper.insertProduct('test product', '40001', 'Collection');
		PricebookEntry PricebookEntry = TestDataHelper.insertPricebookEntry(Test.getStandardPricebookId(), product.Id, 100);

		Order order = TestDataHelper.insertOrder(location.Id, Date.today());
		OrderItem orderItem = TestDataHelper.insertOrderItem(order.Id, product.Id, PricebookEntry.Id);
		DeliveryPackage__c pkg = TestDataHelper.createDeliveryPackage(order.Id);
		pkg.TrackingId__c = 'T12345';
		pkg.Status__c =  DeliveryPackage.STATUS_LABELLED;
		INSERT pkg;

		pkg.Status__c =  DeliveryPackage.STATUS_PACKAGED;
		UPDATE pkg;
	}

	@isTest
	static void parcelforceEventWithOutFinalStatus() {
		DeliveryPackageTrackingFile__c trackingFile = new DeliveryPackageTrackingFile__c(FileName__c = 'Test');
		INSERT trackingFile;

		List<DeliveryPackageTrackingEvent__c> events = new List<DeliveryPackageTrackingEvent__c>();
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I116', DateTime__c = System.now()));
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I115', DateTime__c = System.now().addMinutes(-1)));
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I114', DateTime__c = System.now().addMinutes(-5)));
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I117', DateTime__c = System.now().addMinutes(1)));
		INSERT events;
		Assert.areEqual('I117', [SELECT ParcelforceEvent__c FROM DeliveryPackage__c LIMIT 1].ParcelforceEvent__c);
	}

	@isTest
	static void parcelforceEventWithFinalStatus() {
		DeliveryPackageTrackingFile__c trackingFile = new DeliveryPackageTrackingFile__c(FileName__c = 'Test');
		INSERT trackingFile;

		List<DeliveryPackageTrackingEvent__c> events = new List<DeliveryPackageTrackingEvent__c>();
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I116', DateTime__c = System.now()));
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'IPDF', DateTime__c = System.now().addMinutes(-1))); // Final Status
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I114', DateTime__c = System.now().addMinutes(-5)));
		events.add(new DeliveryPackageTrackingEvent__c(File__c = trackingFile.Id, Name = 'T12345', Code__c = 'I117', DateTime__c = System.now().addMinutes(1)));
		INSERT events;

		Assert.areEqual('IPDF', [SELECT ParcelforceEvent__c FROM DeliveryPackage__c LIMIT 1].ParcelforceEvent__c);
	}
}