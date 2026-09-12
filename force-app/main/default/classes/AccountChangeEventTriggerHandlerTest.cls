@isTest
private class AccountChangeEventTriggerHandlerTest {

	@TestSetup
	static void testdata() {
		BusinessCentralSetting__c bcSetting = new BusinessCentralSetting__c(IsLive__c = true, SendAccount__c = true, SendInvoice__c = true, SendPayment__c = true);
		INSERT bcSetting;

		Test.enableChangeDataCapture();
		Account parent = TestDataHelper.createAccount();
		parent.Enqix_Dead_Live__c = null;
		INSERT parent;

		Account partnership = TestDataHelper.createPartner();
		partnership.Enqix_Dead_Live__c = null;
		INSERT partnership;

		Account location = TestDataHelper.createLocation(parent.Id, partnership.Id);
		location.Enqix_Dead_Live__c = null;
		INSERT location;

		Test.startTest();
		Contact parentContact = TestDataHelper.insertContact(parent.Id, 'testContact1');
		Contact partnerContact = TestDataHelper.insertContact(partnership.Id, 'testContact2');
		Test.stopTest();

		List<AccountContactRelation> acrs = [SELECT Id, Roles FROM AccountContactRelation];
		acrs[0].Roles = AcrUtil.SERVICE_ROLE + ';' + AcrUtil.FINANCE_ROLE;
		acrs[1].Roles = AcrUtil.SERVICE_ROLE + ';' + AcrUtil.FINANCE_ROLE;
		UPDATE acrs;

		List<BusinessCentralSendRequest__c> bcRequests = [SELECT Id, AccountId__c, ContactId__c, AccountReference__c, ContactReference__c FROM BusinessCentralSendRequest__c];
		Assert.isFalse(!bcRequests.isEmpty());
	}

	@isTest
	static void testAccountLive() {
		Test.enableChangeDataCapture();
		Test.startTest();
		List<Account> accounts = [SELECT Id FROM Account];
		for (Account account : accounts) {
			account.Enqix_Dead_Live__c = AccountUtil.LIVE;
			account.Price_Book__c = Test.getStandardPricebookId();
		}
		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		UPDATE accounts;
		Test.stopTest();

		List<BusinessCentralSendRequest__c> bcRequests = [SELECT Id, AccountId__c, ContactId__c, AccountReference__c, ContactReference__c FROM BusinessCentralSendRequest__c];
		Assert.areEqual(5, bcRequests.size()); // Succeeds
	}

	@isTest
	static void testAccountUpdate() {
		Test.enableChangeDataCapture();
		Test.startTest();
		List<Account> accounts = [SELECT Id FROM Account];
		for (Account account : accounts) {
			account.External_Unique_ID__c = 'UnqueId_12345';
		}
		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		UPDATE accounts;
		Test.stopTest();

		List<BusinessCentralSendRequest__c> bcRequests = [SELECT Id, AccountId__c, ContactId__c, AccountReference__c, ContactReference__c FROM BusinessCentralSendRequest__c];

		Assert.areEqual(0, bcRequests.size()); // Succeeds
	}

	@isTest
	static void testContactUpdate() {
		Test.startTest();
		List<Account> accounts = [SELECT Id FROM Account];
		Integer counter = 1000;
		for (Account account : accounts) {
			account.BusinessCentralId__c = String.valueOf(counter);
			account.BusinessCentralContactId__c = String.valueOf(counter);
			counter++;
		}
		UPDATE accounts;

		Test.enableChangeDataCapture();
		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		Contact contact = [SELECT Id FROM Contact WHERE AccountId = :accounts[0].Id];
		contact.FirstName = 'FirstNameUpdated';
		UPDATE contact;
		Test.stopTest();

		List<BusinessCentralSendRequest__c> bcRequests = [SELECT Id, AccountId__c, ContactId__c, AccountReference__c, ContactReference__c FROM BusinessCentralSendRequest__c];
		Assert.areEqual(1, bcRequests.size()); // Succeeds
	}

	@isTest
	static void testTurnOffIntegration() {
		BusinessCentralSetting__c bcSetting = [SELECT Id FROM BusinessCentralSetting__c LIMIT 1];
		bcSetting.IsLive__c = false;
		UPDATE bcSetting;

		Test.enableChangeDataCapture();
		Test.startTest();
		List<Account> accounts = [SELECT Id FROM Account];
		for (Account account : accounts) {
			account.Enqix_Dead_Live__c = AccountUtil.LIVE;
			account.Price_Book__c = Test.getStandardPricebookId();
		}
		Test.setMock(HttpCalloutMock.class, new BusinessCentralMock());
		UPDATE accounts;

		Contact contact = [SELECT Id FROM Contact LIMIT 1];
		UPDATE contact;

		Test.stopTest();

		List<BusinessCentralSendRequest__c> bcRequests = [SELECT Id, AccountId__c, ContactId__c, AccountReference__c, ContactReference__c FROM BusinessCentralSendRequest__c];
		Assert.areEqual(0, bcRequests.size()); // Succeeds
	}

	public class BusinessCentralMock implements HttpCalloutMock {
		private Integer counter = 0;
		private String responseBody = '{"Number": "{0}"}';

		public HTTPResponse respond(HTTPRequest req) {
			counter++;
			HTTPResponse response = new HTTPResponse();
			response.setBody('{"Number": "' + counter + '"}');
			response.setStatusCode(200);
			return response;
		}
	}
}