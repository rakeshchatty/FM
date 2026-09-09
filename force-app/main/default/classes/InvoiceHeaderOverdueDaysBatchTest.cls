@isTest
public class InvoiceHeaderOverdueDaysBatchTest {
	static testMethod void testMethod1() {
		Account parentAccount = TestDataHelper.insertAccount();
		Account account = TestDataHelper.insertLocation(parentAccount.Id, null);

		Invoice_Header__c invoiceHeader = new Invoice_Header__c();
		invoiceHeader.Name = 'FM Invoice Header';
		invoiceHeader.Account__c = parentAccount.Id;
		invoiceHeader.InvoiceFrequency__c = 'Per Order';
		INSERT invoiceHeader;

		Test.startTest();
		InvoiceHeaderOverdueDaysBatch.updateOverdueDays();
		Test.stopTest();
	}
}