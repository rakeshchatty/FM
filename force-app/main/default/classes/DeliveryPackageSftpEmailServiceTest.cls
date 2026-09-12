@isTest
private class DeliveryPackageSftpEmailServiceTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertParcelforceSetting();
		Account parent = TestDataHelper.insertAccount();
        TestDataHelper.insertSupplierFirstMile();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		DeliveryPackage__c pkg = TestDataHelper.createDeliveryPackage(order.Id);
		Test.setMock(WebServiceMock.class, new ParcelforceSoap.ShipmentSuccessMock());
		INSERT pkg;
	}

	@isTest
	static void emailWithoutAttachment() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'Test Email';

		Test.startTest();
		new DeliveryPackageSftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		Integer trackingFile = Integer.valueOf([SELECT Count(Id) trackingIdCount FROM DeliveryPackageTrackingFile__c][0].get('trackingIdCount'));
		Assert.areEqual(0, trackingFile, 'Tracking File created');
	}

	@isTest
	static void emailWithInvalidAttachmentName() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'Test Email';

		Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		binaryAttachment.fileName = 'TestFile.csv';
		binaryAttachment.body = Blob.valueOf('+1+WIRE+CONTRACT+12345678+I104+110113+084500+MK7 8LE+SENDERS REF+1 ITEMS+++');
		email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};

		Test.startTest();
		new DeliveryPackageSftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		List<DeliveryPackageTrackingFile__c> trackingFiles = [SELECT Id FROM DeliveryPackageTrackingFile__c WHERE FileName__c = 'TestFile.csv'];
		Assert.areEqual(0, trackingFiles.size(), 'Tracking File created');
	}

	@isTest
	static void emailWithValidAttachmentName() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'Test Email';

		String todayDate = DateTime.now().format('yyMMdd');

		Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		binaryAttachment.fileName = 'TA0IxyzPQR.csv';
		binaryAttachment.body = Blob.valueOf('+1+WIRE+CONTRACT+12345678+I104+' + todayDate + '+084500+MK7 8LE+SENDERS REF+1 ITEMS+++');
		email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};

		Test.startTest();
		new DeliveryPackageSftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		List<DeliveryPackageTrackingFile__c> trackingFiles = [SELECT Id FROM DeliveryPackageTrackingFile__c WHERE FileName__c = 'TA0IxyzPQR.csv'];
		Assert.areEqual(1, trackingFiles.size(), 'Tracking File not created');

		List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :trackingFiles[0].Id];
		Assert.areEqual(1,attachments.size(), 'Attachment not created');

		List<DeliveryPackageTrackingEvent__c> trackingEvents = [SELECT Name, Code__c, DateTime__c FROM DeliveryPackageTrackingEvent__c];
		Assert.areEqual(1, trackingEvents.size(), 'One tracking event should be created');
		Assert.areEqual('12345678', trackingEvents[0].Name, 'TrackingId Mismatched');
		Assert.areEqual('I104', trackingEvents[0].Code__c, 'Status code Mismatched');
		Assert.areEqual(todayDate + ' 08:45:00', trackingEvents[0].DateTime__c.format('yyMMdd hh:mm:ss'), 'Event datetime Mismatched');
	}
}