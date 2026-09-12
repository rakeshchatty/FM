@isTest
public class InvoiceChangeEventTriggerHandlerTest {
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
		PricebookEntry priceBookEntry = TestDataHelper.insertPricebookEntry(Test.getStandardPricebookId(), product.Id, 100);

		Order order = TestDataHelper.insertOrder(location.Id, System.today());
		TestDataHelper.insertOrderItem(order.Id, product.Id, priceBookEntry.Id);
		TestDataHelper.insertOrderItem(order.Id, product.Id, priceBookEntry.Id);
	}

	@isTest
	static void testPerOrderInvoice() {
		Order order = [SELECT Id FROM Order];
		order.Status = 'Delivered';
		order.Delivery_Date__c = System.today();

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		UPDATE order;
		Test.stopTest();
		Test.getEventBus().deliver();

		List<BusinessCentralSendRequest__c> bcReq = [SELECT Id, InvoiceId__c FROM BusinessCentralSendRequest__c WHERE InvoiceId__c != null];
		Assert.areEqual(1, bcReq.size()); // Succeeds
	}

	@isTest
	static void testMonthlyInvoice() {
		Account location = [SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName = 'Location'];
		location.InvoiceFrequency__c = 'Monthly';
		location.IsInvoiceFrequencyOverride__c = true;
		UPDATE location;

		Order order = [SELECT Id FROM Order];
		order.Status = 'Delivered';
		order.Delivery_Date__c = System.today();
		Test.startTest();
		UPDATE order;
		Test.stopTest();

		Invoice_Header__c invoice = [SELECT Id FROM Invoice_Header__c WHERE status__c = 'Draft' AND InvoiceFrequency__c = 'Monthly'];
		invoice.Status__c = 'Invoiced';

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		UPDATE invoice;
		Test.getEventBus().deliver();

		List<BusinessCentralSendRequest__c> bcReq = [SELECT Id, InvoiceId__c FROM BusinessCentralSendRequest__c WHERE InvoiceId__c != null];
		Assert.areEqual(1, bcReq.size()); // Succeeds
	}

	@isTest
	static void testTurnOffIntegration() {
		BusinessCentralSetting__c bcSetting = [SELECT Id FROM BusinessCentralSetting__c];
		bcSetting.IsLive__c = false;
		UPDATE bcSetting;

		Account location = [SELECT Id, ParentId FROM Account WHERE RecordType.DeveloperName = 'Location'];

		Order order = [SELECT Id FROM Order];
		order.Status = 'Delivered';
		order.Delivery_Date__c = System.today();

		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Test.enableChangeDataCapture();
		Test.startTest();
		UPDATE order;
		Test.stopTest();

		List<BusinessCentralSendRequest__c> bcReq = [SELECT Id, InvoiceId__c FROM BusinessCentralSendRequest__c WHERE InvoiceId__c != null];
		Assert.areEqual(0, bcReq.size()); // Succeeds
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