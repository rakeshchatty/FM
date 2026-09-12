@isTest
private class InvoiceDocRedirectExtensionTest {

    @testSetup
    static void setup() {
        TestDataHelper.insertVat();
		TestDataHelper.insertDefaultLegalEntity('Test Entity');
	}

	@isTest
	static void testPerOrderPDF() {
		Account parent = TestDataHelper.createAccount();
		parent.InvoiceFrequency__c = 'Per Order';
		INSERT parent;
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Order order = TestDataHelper.insertOrder(location.Id);
		Product2 product = TestDataHelper.insertProduct('Test Name', 'Test Code', 'Delivery');
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
		TestDataHelper.insertOrderItem(order.Id, product.Id, pbe.Id);

		order.Delivery_Date__c = System.today();
		order.Status = 'Delivered';
		Test.startTest();
		UPDATE order;
		Test.stopTest();

		Invoice_Header__c invoice = [SELECT Id FROM Invoice_Header__c];
		new InvoiceExtensionPerOrder(new ApexPages.StandardController(invoice));
		new InvoiceDocRedirectExtension(invoice).redirect();
	}

	@isTest
	static void testMonthlyPDF() {
		Account parent = TestDataHelper.createAccount();
		parent.InvoiceFrequency__c = 'Monthly';
		INSERT parent;
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Order order1 = TestDataHelper.createOrder(location.Id, null);
		Order order2 = TestDataHelper.createOrder(location.Id, null);
		order1.PO_Number__c = 'SomePoNumber';
		INSERT new List<Order> { order1, order2 };
		Product2 product = TestDataHelper.insertProduct('Test Name', 'Test Code', 'Delivery');
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
		TestDataHelper.insertOrderItem(order1.Id, product.Id, pbe.Id);
		TestDataHelper.insertOrderItem(order2.Id, product.Id, pbe.Id);

		order1.Delivery_Date__c = order2.Delivery_Date__c = System.today();
		order1.Status = order2.Status = 'Delivered';
		Test.startTest();
		UPDATE new List<Order> { order1, order2 };
		Test.stopTest();

		Invoice_Header__c invoice = [SELECT Id FROM Invoice_Header__c];
		new InvoiceExtension(new ApexPages.StandardController(invoice));
		new InvoiceDocRedirectExtension(invoice).redirect();
	}
}