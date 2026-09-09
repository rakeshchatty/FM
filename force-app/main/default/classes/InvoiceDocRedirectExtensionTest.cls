@isTest
public class InvoiceDocRedirectExtensionTest {
    
    @isTest
    private static void testPerOrderPDF() {
        Account parent = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parent.Id, null);
        Contact contact = TestDataHelper.insertContact(location.Id, 'firstMile');
        TestDataHelper.insertAccountContactRelation(parent.Id, contact.Id, 'Finance Contact');
        Order order = TestDataHelper.insertOrder(location.Id);
        Invoice_Header__c invoice = TestDataHelper.insertInvoice(location.Id, order.Id, Invoicing.FREQUENCY_IMMEDIATE);
        Invoice_Line__c invoiceLine = TestDataHelper.insertInvoiceLine(invoice.Id);
        
        InvoiceDocRedirectExtension idre = new InvoiceDocRedirectExtension(invoice);
        PageReference p = idre.redirect();
    }
    
    @isTest
    private static void testMonthlyPDF() {
        Account parent = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parent.Id, null);
        Contact contact = TestDataHelper.insertContact(location.Id, 'firstMile');
        TestDataHelper.insertAccountContactRelation(parent.Id, contact.Id, 'Finance Contact');
        Order order = TestDataHelper.insertOrder(location.Id);
        Invoice_Header__c invoice = TestDataHelper.insertInvoice(location.Id, order.Id, Invoicing.FREQUENCY_MONTHLY);
        Invoice_Line__c invoiceLine = TestDataHelper.insertInvoiceLine(invoice.Id);
        
        InvoiceDocRedirectExtension idre = new InvoiceDocRedirectExtension(invoice);
        PageReference p = idre.redirect();
    }
}