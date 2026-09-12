@isTest
public class XpandIT_CreditNote_Controller_Test {

	@testSetup
	static void makeData() {
		TestDataHelper.insertVat();

		Product_Category__c pc = new Product_Category__c();
		pc.Name = 'test';
		pc.Enqix_Id__c = 1;
		pc.Product_Category_Key__c = 'test';
		insert pc;

		Product2 prod = TestDataHelper.createProduct('Credit', '333', 'Delivery', pc.Id, null, null, '1');
		prod.Family = 'Hardware';
		INSERT prod;
		
		INSERT new CreditSetting__c(ProductId__c = prod.Id);
		
		// 1. Insert a price book entry for the standard price book.
		// Standard price book entry
		PricebookEntry standardPrice = TestDataHelper.insertStandardPricebookEntry(prod.Id, 1000);

		Test.setMock(HttpCalloutMock.class, new DoogalTest.RestMock('TW1 2RS	51.452903	-0.317551	Postcode terminated prior to Gridlink initiative - last known ONS postcode grid reference	Twickenham	Richmond upon Thames	Twickenham Riverside	Richmond upon Thames 009C	Greater London	London	England		10.66619777679443	Urban major conurbation	Slough and Heathrow	E01003894'));
		Account parentAccount = TestDataHelper.createAccount();
		parentAccount.Enqix_ID__c = '1234566777';
		parentAccount.BusinessCentralId__c = 'Parent-BC-Id-01';
		parentAccount.BusinessCentralContactId__c = 'Parent-FC-BC-Id-01';
		insert parentAccount;

		Account partnerAccount = TestDataHelper.createPartner();
		partnerAccount.Enqix_ID__c = '1234212';
		partnerAccount.Enqix_Classification__c = 'BID';
		partnerAccount.InvoiceFrequency__c = 'Monthly';
		partnerAccount.BusinessCentralId__c = 'Partner-BC-Id-01';
		partnerAccount.BusinessCentralContactId__c = 'Partner-FC-BC-Id-01';
		insert partnerAccount;

		Account childAccount = TestDataHelper.createLocation(parentAccount.Id, null);
		childAccount.BillingPostalCode = 'NW6 1NR';
		childAccount.Enqix_Location_ID__c  = 'ABC123';
		childAccount.Enqix_Classification__c = 'BID';
		childAccount.Enqix_ID__c = '1234';
		childAccount.BusinessCentralId__c = 'Location-BC-Id-01';
		insert childAccount;

		Account childAccountPartner = TestDataHelper.createLocation(parentAccount.Id, partnerAccount.Id);
		childAccountPartner.BillingPostalCode = 'NW6 2NR';
		childAccountPartner.Enqix_Location_ID__c  = 'ABC33123';
		childAccountPartner.Enqix_Classification__c = 'BID';
		childAccountPartner.Enqix_ID__c = '12323234';
		childAccountPartner.BusinessCentralId__c = 'Location-BC-Id-02';
		insert childAccountPartner;

		List <Account> childAccountList = [SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c, Price_Book__c FROM  Account where RecordType.Name = 'Location' LIMIT 1];

		TestDataHelper.insertSupplier('First Mile Ltd');
		test.startTest();
		system.debug('Number of queries: '  +Limits.getQueries());

		Id partnerD = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();

		Account_Discount__c desconto = new Account_Discount__c(
			Account__c = partnerAccount.Id,
			DiscountSupStartDate__c = system.today(),
			DiscountSupEndDate__c = system.today() + 2,
			Product__c = prod.Id,
			RecordTypeId = partnerD,
			Gross_Price__c = 200,
			BID_Price__c = 10,
			Product_Discount__c = 10
		);
		insert desconto;

		Order order = TestDataHelper.createOrder(childAccount.Id, System.today());
		order.Status = 'Draft';
		order.Pricebook2Id = childAccount.Price_Book__c;
		order.Type = 'Contractor';
		insert order;

		Order order2 = TestDataHelper.createOrder(childAccountPartner.Id, System.today());
		order2.Status = 'Draft';
		order2.Pricebook2Id = childAccountPartner.Price_Book__c;
		order2.Type = 'Contractor';
		insert order2;

		List<OrderItem> ops = new List<OrderItem>();

		OrderItem op3 = TestDataHelper.createOrderItem(order.Id, prod.Id, standardPrice.Id);
		op3.ListPrice__c = 1;
		op3.Description__c = '123';
		op3.Discount_to_Apply__c = 'Account';
		ops.add(op3);

		OrderItem op4 = TestDataHelper.createOrderItem(order2.Id, prod.Id, standardPrice.Id);
		op4.ListPrice__c = 1;
		op4.Description__c = '1234';
		op4.Discount_to_Apply__c = 'Partner';
		ops.add(op4);
		insert ops;

		test.stopTest();
	}

	@isTest
	static void test_method_one() {
		test.startTest();
		List<Invoice_Header__c> invoices = [SELECT Id, Account__c,Account__r.RecordTypeId, Location__c, InvoiceFrequency__c, Location__r.Price_Book__c, Account__r.Price_Book__c FROM Invoice_Header__c];
		System.debug('invoicesLength' + invoices.size());
		System.debug('invoicesasd' + invoices);
		Invoice_Header__c invoice = invoices.get(0);

		Id recordTypePartner = [SELECT RecordTypeId FROM Account WHERE Name = 'Partner'].RecordTypeId;
		System.debug('Account__r.RecordTypeId' + recordTypePartner);
		Invoice_Header__c invoicePartner = [SELECT Id, Account__c, Location__c, InvoiceFrequency__c FROM Invoice_Header__c WHERE Account__r.RecordTypeId = :recordTypePartner LIMIT 1];
		List<Invoice_Line__c> invoicesLines = [SELECT Id, Location_Id__c, Product__c FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :invoice.Id];
		system.debug('invoicesLines -->'+invoicesLines);
		//system.assertEquals(3,invoices.size());

		// BC ID Update
		List<Invoice_Header__c> invoicesToUpdate = new List<Invoice_Header__c>();
		invoicesToUpdate.add(new Invoice_Header__c(Id = invoice.Id, BusinessCentralId__c = 'Invoice-BC-Id-01'));
		invoicesToUpdate.add(new Invoice_Header__c(Id = invoicePartner.Id, BusinessCentralId__c = 'Invoice-BC-Id-02'));
		UPDATE invoicesToUpdate;

		String test1 = XpandIT_CreditNote_Controller.getInvoiceResumeData(invoice.Id);
		//system.assertEquals(invoice.Account__c+'/Per Order', invoice.Account__c+'/'+invoice.InvoiceFrequency__c);

		List<Account> accounts = XpandIT_CreditNote_Controller.getAccountsLocations(invoice.Id, invoice.Account__c);
		//system.assertEquals(1, accounts.size());

		List<Order> orders = XpandIT_CreditNote_Controller.getLocationsOrders(invoice.Id, invoice.Location__c);
		//system.assertEquals(1, orders.size());

		List<OrderItem> orderProducts2 = XpandIT_CreditNote_Controller.generateCreditOrder(invoice.Id, orders.get(0).Id);
		//system.assertEquals(1, orderProducts2.size());

		List<OrderItem> orderProducts2_2 = XpandIT_CreditNote_Controller.generateCreditOrder(invoice.Id);

		List<OrderItem> orderProductsPartner = XpandIT_CreditNote_Controller.generateCreditOrder(invoicePartner.Id);
		//system.assertEquals(1, orderProducts2_2.size());
		Boolean worked = XpandIT_CreditNote_Controller.createCreditOrder(orderProducts2_2, 'notes', invoice.Id, invoice.Location__c, false, true, 'Service');
		//system.assertEquals(true, worked);
		Boolean workedPartner = XpandIT_CreditNote_Controller.createCreditOrder(orderProducts2, 'notes', invoicePartner.Id, invoicePartner.Account__c, true, true, 'Service');
		//system.assertEquals(true, worked);

		Boolean simpleNoteWorked = XpandIT_CreditNote_Controller.createSimpleCreditOrder(10, 'notes', invoice.Id, invoice.Location__c, true, 'Service');
		//system.assertEquals(true, simpleNoteWorked);
		test.stopTest();
	}
}