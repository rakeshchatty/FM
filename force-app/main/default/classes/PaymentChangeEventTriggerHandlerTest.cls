@isTest
private without sharing class PaymentChangeEventTriggerHandlerTest {

	@TestSetup
	static void testdata() {
		BusinessCentralSetting__c bcSetting = new BusinessCentralSetting__c(IsLive__c = true, SendAccount__c = true, SendInvoice__c = true, SendPayment__c = true);
		INSERT bcSetting;

		TestDataHelper.insertVat();

		Account parent = TestDataHelper.createAccount();
		parent.BusinessCentralId__c = '1234';
		INSERT parent;

		Account partnership = TestDataHelper.createPartner();
		partnership.BusinessCentralId__c = '456';
		INSERT partnership;

		Account location = TestDataHelper.createLocation(parent.Id, partnership.Id);
		location.BusinessCentralId__c = '789';
		INSERT location;

		Contact parentContact = TestDataHelper.insertContact(parent.Id, 'testContact1');
		Contact partnerContact = TestDataHelper.insertContact(partnership.Id, 'testContact2');

		AccountContactRelation acr = new AccountContactRelation(AccountId = location.Id, ContactId = parentContact.Id, Roles = AcrUtil.SERVICE_ROLE);
		INSERT acr;

		TestDataHelper.insertSupplier('First Mile Ltd');

		Product2 product = TestDataHelper.insertProduct('FirstMile', '1234', 'Collection');
		PricebookEntry priceBookEntry = TestDataHelper.insertStandardPricebookEntry(product.Id, 100);
		order order = TestDataHelper.insertOrder(location.Id, System.today());
		OrderItem orderItems = TestDataHelper.insertOrderItem(order.Id, product.Id, priceBookEntry.Id);

		order.Status = 'Delivered';
		order.Delivery_Date__c = System.today();
		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		UPDATE order;
		Test.getEventBus().deliver();
		Test.stopTest();
	}

	@isTest
	static void testInvoicePayment() {
		Invoice_Header__c invoice = [SELECT Id, Account__c FROM Invoice_Header__c LIMIT 1];
		Bank_Statement__c bs = new Bank_Statement__c(Transaction_Details__c = 'Test Transaction Details');
		bs.Transaction_Type__c = 'Credit Card';
		bs.Account__c = invoice.Account__c;
		bs.Receipt_Amount__c = 100;
		bs.Entry_Date__c = System.today();
		bs.Document_Name__c = 'Charge for [' + invoice.Id + ']';

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		INSERT bs;
		Test.getEventBus().deliver();
		Test.stopTest();

		Bank_Statement__c bankStatement = [SELECT Id, BusinessCentralId__c FROM Bank_Statement__c WHERE Id = :bs.Id];
		Assert.isNotNull(bankStatement.BusinessCentralId__c, 'BusinessCentral Id must be available.'); // Succeeds

		BusinessCentralSendRequest__c bcReq = [SELECT Id, PaymentId__c, PaymentReference__c FROM BusinessCentralSendRequest__c WHERE PaymentReference__c != null LIMIT 1];
		Assert.areEqual(bcReq.PaymentId__c, bs.Id); // Succeeds
		Assert.isNotNull(bcReq.PaymentReference__c, 'BusinessCentral Id must be available.'); // Succeeds
	}

	@isTest
	static void testOrderPayment() {
		Invoice_Header__c invoice = [SELECT Id, Account__c, OrderLookUp__c FROM Invoice_Header__c LIMIT 1];
		Bank_Statement__c bs = new Bank_Statement__c(Transaction_Details__c = 'Test Transaction Details', Document_Name__c = 'Test order');
		bs.Transaction_Type__c = 'Credit Card';
		bs.Account__c = invoice.Account__c;
		bs.Receipt_Amount__c = 100;
		bs.Entry_Date__c = System.today();
		bs.Order__c = invoice.OrderLookUp__c;

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		INSERT bs;
		Test.getEventBus().deliver();
		Test.stopTest();

		Bank_Statement__c bankStatement = [SELECT Id, BusinessCentralId__c FROM Bank_Statement__c WHERE Id = :bs.Id];
		Assert.isNotNull(bankStatement.BusinessCentralId__c, 'BusinessCentral Id must be available.'); // Succeeds

		BusinessCentralSendRequest__c bcReq = [SELECT Id, PaymentId__c, PaymentReference__c FROM BusinessCentralSendRequest__c WHERE PaymentReference__c != null LIMIT 1];
		Assert.areEqual(bcReq.PaymentId__c, bs.Id); // Succeeds
		Assert.isNotNull(bcReq.PaymentReference__c, 'BusinessCentral Id must be available.'); // Succeeds
	}

	@isTest
	static void testAccountPayment() {
		Invoice_Header__c invoice = [SELECT Id, Account__c FROM Invoice_Header__c LIMIT 1];
		Bank_Statement__c bs = new Bank_Statement__c(Transaction_Details__c = 'Test Transaction Details', Document_Name__c = 'Test order');
		bs.Transaction_Type__c = 'Credit Card';
		bs.Account__c = invoice.Account__c;
		bs.Receipt_Amount__c = 100;
		bs.Entry_Date__c = System.today();

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		INSERT bs;
		Test.getEventBus().deliver();
		Test.stopTest();

		Bank_Statement__c bankStatement = [SELECT Id, BusinessCentralId__c FROM Bank_Statement__c WHERE Id = :bs.Id];
		Assert.isNotNull(bankStatement.BusinessCentralId__c, 'BusinessCentral Id must be available.'); // Succeeds

		BusinessCentralSendRequest__c bcReq = [SELECT Id, PaymentId__c, PaymentReference__c FROM BusinessCentralSendRequest__c WHERE PaymentReference__c != null LIMIT 1];
		Assert.areEqual(bcReq.PaymentId__c, bs.Id); // Succeeds
		Assert.isNotNull(bcReq.PaymentReference__c, 'BusinessCentral Id must be available.'); // Succeeds
	}

	@isTest
	static void testPaymentUpdate() {
		Invoice_Header__c invoice = [SELECT Id, Account__c FROM Invoice_Header__c LIMIT 1];
		Bank_Statement__c bs = new Bank_Statement__c(Transaction_Details__c = 'Test Transaction Details', Document_Name__c = 'Test order');
		bs.Transaction_Type__c = 'Credit Card';
		bs.Account__c = invoice.Account__c;
		bs.Receipt_Amount__c = 100;
		bs.Entry_Date__c = System.today();

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		INSERT bs;
		Test.getEventBus().deliver();

		List<BusinessCentralSendRequest__c> bcReq1 = [SELECT Id, PaymentId__c, PaymentReference__c FROM BusinessCentralSendRequest__c WHERE PaymentId__c != null];
		Assert.areEqual(1, bcReq1.size()); // Succeeds

		bs.Unallocated_Amount__c = 0;

		Test.startTest();
		UPDATE bs;
		Test.getEventBus().deliver();
		Test.stopTest();

		List<BusinessCentralSendRequest__c> bcReq2 = [SELECT Id, PaymentId__c, PaymentReference__c FROM BusinessCentralSendRequest__c WHERE PaymentId__c != null AND PaymentId__c != :bs.Id];
		Assert.areEqual(0, bcReq2.size()); // Succeeds
	}

	@isTest
	static void testTurnOffIntegration() {
		BusinessCentralSetting__c bcSetting = [SELECT Id FROM BusinessCentralSetting__c LIMIT 1];
		bcSetting.IsLive__c = false;
		UPDATE bcSetting;

		Invoice_Header__c invoice = [SELECT Id, Account__c FROM Invoice_Header__c LIMIT 1];
		Bank_Statement__c bs = new Bank_Statement__c(Transaction_Details__c = 'Test Transaction Details', Document_Name__c = 'Test order');
		bs.Transaction_Type__c = 'Credit Card';
		bs.Account__c = invoice.Account__c;
		bs.Receipt_Amount__c = 100;
		bs.Entry_Date__c = System.today();

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		INSERT bs;
		Test.getEventBus().deliver();
		Test.stopTest();

		Bank_Statement__c bankStatement = [SELECT Id, BusinessCentralId__c FROM Bank_Statement__c WHERE Id = :bs.Id];
		Assert.isNull(bankStatement.BusinessCentralId__c); // Succeeds

		List<BusinessCentralSendRequest__c> bcReq = [SELECT Id, PaymentId__c, PaymentReference__c FROM BusinessCentralSendRequest__c WHERE PaymentId__c != null LIMIT 1];
		Assert.areEqual(0, bcReq.size()); // Succeeds
	}

	public class BusinessCentralMock implements HttpCalloutMock {
		private Integer counter = 0;

		public HTTPResponse respond(HTTPRequest req) {
			counter++;
			HTTPResponse response = new HTTPResponse();
			response.setBody('{"documentNumber": "' + counter + '"}');
			response.setStatusCode(200);
			return response;
		}
	}
}