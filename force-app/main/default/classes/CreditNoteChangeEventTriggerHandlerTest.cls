@isTest
public class CreditNoteChangeEventTriggerHandlerTest {
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

		Order order = TestDataHelper.insertOrder(location.Id, System.today());
		OrderItem orderItems = TestDataHelper.insertOrderItem(order.Id, product.Id, priceBookEntry.Id);

		order.Status = 'Delivered';
		order.Delivery_Date__c = System.today();

		Test.startTest();
		UPDATE order;
		Test.stopTest();
	}

	@isTest
	static void testCreditNote() {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		Product2 product = [SELECT Id FROM Product2 LIMIT 1];
		Invoice_Header__c originalInvoice = [SELECT Id FROM Invoice_Header__c LIMIT 1];
		originalInvoice.BusinessCentralId__c = 'ABC';
		UPDATE originalInvoice;

		Order creditOrder = new Order(
			AccountId = location.Id,
			Order_Placed_Date__c = System.today(),
			EffectiveDate = System.today(),
			Type = 'Invoicing',
			Status = 'Draft',
			Original_Invoice_to_Credit__c = originalInvoice.Id,
			PO_Number__c = 'Credit Note',
			Pricebook2Id = Test.getStandardPricebookId()
		);
		INSERT creditOrder;

		OrderItem creditOrderProduct = new OrderItem(
			Product2Id = product.Id,
			Quantity = -1,
			ListPrice__c = 100,
			OrderId = creditOrder.Id,
			Price_Book__c = Test.getStandardPricebookId(),
			Credit_Note_line__c = true
		);

		Test.enableChangeDataCapture();
		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.startTest();
		INSERT creditOrderProduct;
		Test.stopTest();
		Test.getEventBus().deliver();

		List<Invoice_Header__c> invoices = [SELECT Id, Status__c, Original_Invoice_to_Credit__c FROM Invoice_Header__c];
		Assert.areEqual(2, invoices.size());

		List<BusinessCentralSendRequest__c> bcReq = [SELECT Id, InvoiceId__c FROM BusinessCentralSendRequest__c WHERE InvoiceId__c != null];
		Assert.areEqual(1, bcReq.size());
	}

	public class BusinessCentralMock implements HttpCalloutMock {
		private Integer counter = 0;

		public HTTPResponse respond(HTTPRequest req) {
			counter++;
			HTTPResponse response = new HTTPResponse();
			response.setBody('{"salesforceId": "' + counter + '"}');
			response.setStatusCode(200);
			return response;
		}
	}
}