@isTest
public without sharing class DeleteSendInvoiceEmailSchedularTest {

    @TestSetup
    static void testSetup(){
        TestDataHelper.insertSendGridSetting();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertContact(parent.Id, 'FirstMile');
		Order order = TestDataHelper.insertOrder(location.Id);
		Invoice_Header__c invoice1 = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
		Invoice_Header__c invoice2 = TestDataHelper.insertInvoice(parent.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
		TestDataHelper.insertInvoiceLine(invoice1.Id);
		TestDataHelper.insertInvoiceLine(invoice2.Id);
        SendInvoiceEmail__c sendInvoice1 = new SendInvoiceEmail__c(Invoice__c = invoice1.Id, Status__c = 'Sent');
        SendInvoiceEmail__c sendInvoice2 = new SendInvoiceEmail__c(Invoice__c = invoice2.Id, Status__c = 'Sent');
        INSERT sendInvoice1;
        INSERT sendInvoice2;
        Test.setCreatedDate(sendInvoice2.Id, System.now().addDays(-31));
    }

    @isTest
    static void deleteSendInvoiceEmails() {
        Assert.areEqual(1, [SELECT Id FROM SendInvoiceEmail__c WHERE IsScheduledForDeletion__c = true].size());
        Test.startTest();
        new DeleteSendInvoiceEmailSchedular().execute(null);
        Test.stopTest();
        Assert.areEqual(0, [SELECT Id FROM SendInvoiceEmail__c WHERE IsScheduledForDeletion__c = true].size());
    }
}