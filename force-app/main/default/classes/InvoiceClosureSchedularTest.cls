@isTest
public class InvoiceClosureSchedularTest {
	@testSetup static void setupMethod() {
		TestDataHelper.insertVat();
		
		Account parentAccount = new Account();
		parentAccount.Name = 'FM Account';
		parentAccount.InvoiceFrequency__c = Invoicing.FREQUENCY_MONTHLY;
		parentAccount.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		INSERT parentAccount;
		
		Account childLocation = new Account();
		childLocation.Name = 'FM Location';
		childLocation.ParentId = parentAccount.Id;
		childLocation.IsInvoiceFrequencyOverride__c = true;
		childLocation.InvoiceFrequency__c = Invoicing.FREQUENCY_MONTHLY;
		childLocation.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
		INSERT childLocation;

		Date yesterday = System.today() - 1;
		List<Invoice_Header__c> invoiceHeaderList = new List<Invoice_Header__c>();
		invoiceHeaderList.add(new Invoice_Header__c(Name = 'Periodic Invoice', Account__c = parentAccount.Id, Location__c = childLocation.Id, Status__c = Invoicing.STATUS_OPEN,
													Salesforce__c = true, InvoiceFrequency__c = Invoicing.FREQUENCY_MONTHLY, DueDate__c = yesterday));
		invoiceHeaderList.add(new Invoice_Header__c(Name = 'Immediate Invoice', Account__c = parentAccount.Id, Location__c = childLocation.Id, Status__c = Invoicing.STATUS_OPEN,
													Salesforce__c = true, InvoiceFrequency__c = Invoicing.FREQUENCY_IMMEDIATE, DueDate__c = yesterday));

		INSERT invoiceHeaderList;
	}

	static testMethod void closeInvoice1() {
		Invoice_Header__c immediateInvoice = [SELECT Status__c FROM Invoice_Header__c WHERE Name = 'Immediate Invoice'];
		System.assertEquals(immediateInvoice.Status__c, Invoicing.STATUS_CLOSED, 'Invoice must be closed on creation' );

		Invoice_Header__c periodicInvoice = [SELECT Status__c FROM Invoice_Header__c WHERE Name = 'Periodic Invoice'];
		System.assertEquals(periodicInvoice.Status__c, Invoicing.STATUS_OPEN, 'Invoice must be open before batch execution' );

		InvoiceClosureScheduler invoiceClosureSch = new InvoiceClosureScheduler();
		Test.startTest();
		invoiceClosureSch.execute(null);
		Test.stopTest();

		periodicInvoice = [SELECT Status__c FROM Invoice_Header__c WHERE Name = 'Periodic Invoice'];
		System.assertEquals(periodicInvoice.Status__c, Invoicing.STATUS_CLOSED, 'Invoice must be closed after batch execution' );
	}

	static testMethod void closeInvoice2() {
		Invoice_Header__c immediateInvoice = [SELECT Status__c FROM Invoice_Header__c WHERE Name = 'Immediate Invoice'];
		System.assertEquals(immediateInvoice.Status__c, Invoicing.STATUS_CLOSED, 'Invoice must be closed on creation' );

		Invoice_Header__c periodicInvoice = [SELECT Status__c FROM Invoice_Header__c WHERE Name = 'Periodic Invoice'];
		System.assertEquals(periodicInvoice.Status__c, Invoicing.STATUS_OPEN, 'Invoice must be open before batch execution' );

		Test.startTest();
		new InvoiceClosureScheduler().execute(null);
		Test.stopTest();

		periodicInvoice = [SELECT Status__c FROM Invoice_Header__c WHERE Name = 'Periodic Invoice'];
		System.assertEquals(periodicInvoice.Status__c, Invoicing.STATUS_CLOSED, 'Invoice must be closed after batch execution' );
	}
}