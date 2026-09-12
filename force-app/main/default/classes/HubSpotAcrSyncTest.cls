@isTest
private class HubSpotAcrSyncTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.createAccount();
		parent.HubSpotId__c = 40085559700.0;
		INSERT parent;
		Account location = TestDataHelper.createLocation(parent.Id, null);
		location.HubSpotId__c = 40085559701.0;
		INSERT location;
		Contact contact = TestDataHelper.insertContact(parent.Id, 'SomeName', 80056668000.0);
	}

	@isTest
	static void insertWithOutHubSpotIdACR() {
		Contact contact = [SELECT Id FROM Contact];
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location'];
		location.HubSpotId__c = null;
		UPDATE location;

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		AccountContactRelation acr = TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');
		Test.stopTest();

		AccountContactRelation processedAcr = [SELECT HubSpotSyncStatus__c, HubSpotSyncMessage__c FROM AccountContactRelation WHERE IsDirect = false];
		Assert.areEqual('Error', processedAcr.HubSpotSyncStatus__c);
		Assert.areEqual('Either HubSpot CompanyId or HubSpot ContactId is empty.', processedAcr.HubSpotSyncMessage__c);
	}

	@isTest
	static void insertACR() {
		Contact contact = [SELECT Id FROM Contact];
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location'];

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		AccountContactRelation acr = TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');
		Test.stopTest();
	}

	@isTest
	static void updateACR() {
		AccountContactRelation acr = [SELECT Id FROM AccountContactRelation];

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		acr.Roles = 'Finance Contact;Order Contact;Service Contact';
		UPDATE acr;
		Test.stopTest();
	}

	@isTest
	static void updateACRError() {
		AccountContactRelation acr = [SELECT Id FROM AccountContactRelation];

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		acr.Roles = 'Finance Contact;Order Contact;Service Contact';
		UPDATE acr;
		Test.stopTest();
	}

	@isTest
	static void updateWithOutHubSpotId() {
		Contact contact = [SELECT Id FROM Contact];
		contact.HubSpotId__c = null;
		UPDATE contact;

		AccountContactRelation acr = [SELECT Id, contactId FROM AccountContactRelation];
		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		acr.Roles = 'Finance Contact;Order Contact;Service Contact';
		UPDATE acr;
		Test.stopTest();

		AccountContactRelation processedAcr = [SELECT HubSpotSyncStatus__c, HubSpotSyncMessage__c FROM AccountContactRelation];
		Assert.areEqual('Error', processedAcr.HubSpotSyncStatus__c);
		Assert.areEqual('Either HubSpot CompanyId or HubSpot ContactId is empty.', processedAcr.HubSpotSyncMessage__c);
	}

	@isTest
	static void statusToRetry() {
		AccountContactRelation acr = [SELECT Id FROM AccountContactRelation];

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		acr.HubSpotSyncStatus__c = 'Retry';
		UPDATE acr;
		Test.stopTest();
	}

	@isTest
	static void rolesToNull() {
		Contact contact = [SELECT Id FROM Contact];
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location'];
		AccountContactRelation acr = TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
		acr.Roles = '';
		UPDATE acr;
		Test.stopTest();
	}

	private class Mock implements HttpCalloutMock {

		Boolean isError = false;

		private Mock() {}

		private Mock(Boolean isError) {
			this.isError = isError;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HttpResponse res = new HttpResponse();
			if (isError) {
				res.setStatusCode(200);
			} else {
				res.setStatusCode(400);
			}
			return res;
		}
	}
}