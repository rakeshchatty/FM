@isTest
private class RoyalMailSftpEmailServiceTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertRoyalMailSetting();
		TestDataHelper.insertSupplierFirstMile();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_NEW, DeliveryPackage.CARRIER_ROYAL_MAIL);
	}

	@isTest
	static void emailWithoutAttachment() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'Test Email';

		Test.startTest();
		new RoyalMailSftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		Integer trackingFile = Integer.valueOf([SELECT Count(Id) trackingIdCount FROM DeliveryPackageTrackingFile__c][0].get('trackingIdCount'));
		Assert.areEqual(0, trackingFile);
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
		new RoyalMailSftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		List<DeliveryPackageTrackingFile__c> trackingFiles = [SELECT Id FROM DeliveryPackageTrackingFile__c WHERE FileName__c = 'TestFile.csv'];
		Assert.areEqual(0, trackingFiles.size());
	}

	@isTest
	static void emailWithValidAttachment() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'Test Email';

		String todayDate = DateTime.now().format('yyyyMMdd');

		Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		binaryAttachment.fileName = 'TA0IxyzPQR.csv';
		binaryAttachment.body = Blob.valueOf('D,ABCD,"12345678","2000073638","XX155XX","Delivery Address","EVKSF","1214","' + todayDate + '","165213","TPM01","XX43XX",,,');
		email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};

		Test.startTest();
		new RoyalMailSftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		List<DeliveryPackageTrackingFile__c> trackingFiles = [SELECT Id FROM DeliveryPackageTrackingFile__c WHERE FileName__c = 'TA0IxyzPQR.csv'];
		Assert.areEqual(1, trackingFiles.size());

		List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentId = :trackingFiles[0].Id];
		Assert.areEqual(1, attachments.size());

		DeliveryPackageTrackingEvent__c trackingEvent = [SELECT Name, Code__c, DateTime__c FROM DeliveryPackageTrackingEvent__c];
		Assert.areEqual('12345678', trackingEvent.Name);
		Assert.areEqual('EVKSF', trackingEvent.Code__c);
		Assert.areEqual(todayDate + ' 16:52:13', trackingEvent.DateTime__c.formatGmt('yyyyMMdd HH:mm:ss'));
	}
}