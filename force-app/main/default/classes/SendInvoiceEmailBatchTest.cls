@isTest
public with sharing class SendInvoiceEmailBatchTest {

	@isTest
	static void withoutEmailEnabled() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);

		INSERT new SendInvoiceEmail__c(Invoice__c = invoice.Id);
		new SendInvoiceEmailBatch().execute(null);
	}

	@isTest
	static void withoutInvoiceLines() {
		TestDataHelper.insertSendGridSetting();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);

		INSERT new SendInvoiceEmail__c(Invoice__c = invoice.Id);
		new SendInvoiceEmailBatch().execute(null);
	}

	@isTest
	static void withoutFinanceContact() {
		TestDataHelper.insertSendGridSetting();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
		TestDataHelper.insertInvoiceLine(invoice.Id);

		INSERT new SendInvoiceEmail__c(Invoice__c = invoice.Id);
		new SendInvoiceEmailBatch().execute(null);
	}

	@isTest
	static void withFinanceContactAndLines() {
		TestDataHelper.insertSendGridSetting();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertContact(parent.Id, 'FirstMile');
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice1 = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
		Invoice_Header__c invoice2 = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
		TestDataHelper.insertInvoiceLine(invoice1.Id);
		TestDataHelper.insertInvoiceLine(invoice2.Id);

		INSERT new SendInvoiceEmail__c(Invoice__c = invoice1.Id);
		INSERT new SendInvoiceEmail__c(Invoice__c = invoice2.Id);
		new SendInvoiceEmailBatch().execute(null);
	}
}