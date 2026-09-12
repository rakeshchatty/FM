@isTest
public class SendInvoiceEmailTest {

	@testSetup
	private static void testSetup() {
		TestDataHelper.insertSendGridSetting();
	}

	@isTest
	private static void testPerOrderPDF() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertContact(parent.Id, 'FirstMile1');
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
		Invoice_Line__c invoiceLine = TestDataHelper.insertInvoiceLine(invoice.Id);

		List<ContentDocumentLink> contentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoice.Id];
		Assert.isTrue(contentDocumentLinks.isEmpty());
		SendInvoiceEmail.send(new Id[] {invoice.Id});
		SendInvoiceEmail.send(new Id[] {invoice.Id});
		contentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :invoice.Id];
		Assert.isFalse(contentDocumentLinks.isEmpty());

		List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :contentDocumentLinks[0].ContentDocumentId];
		Assert.areEqual(1, contentVersions.size());
	}

	@isTest
	private static void testMonthlyPDF() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertContact(parent.Id, 'FirstMile1');
		TestDataHelper.insertContact(parent.Id, 'FirstMile2');
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_MONTHLY);
		Invoice_Line__c invoiceLine = TestDataHelper.insertInvoiceLine(invoice.Id);

		List<ContentDocumentLink> contentDocumentLinks = [SELECT Id FROM ContentDocumentLink WHERE LinkedEntityId = :invoice.Id];
		Assert.isTrue(contentDocumentLinks.isEmpty());
		Test.startTest();
		SendInvoiceEmail.send(new Id[] {invoice.Id});
		Test.stopTest();
		contentDocumentLinks = [SELECT Id, ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :invoice.Id];
		Assert.isFalse(contentDocumentLinks.isEmpty());
		List<ContentVersion> contentVersions = [SELECT Id FROM ContentVersion WHERE ContentDocumentId = :contentDocumentLinks[0].ContentDocumentId];
		Assert.areEqual(1, contentVersions.size());
	}
}