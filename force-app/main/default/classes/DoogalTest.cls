@isTest
public class DoogalTest {

    @isTest
    private static void testNoPostCode() {
        Id parentRecord = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account account = new Account(Name='Test Account', recordTypeId = parentRecord);
        Test.startTest();
        INSERT account;
        Test.stopTest();

        account = [SELECT Council__c, IsCouncilUpdatedViaDoogle__c FROM Account WHERE Id = :account.Id];
        Assert.isNull(account.Council__c);
        Assert.isFalse(account.IsCouncilUpdatedViaDoogle__c);
    }

    @isTest
    private static void testPartialPostCode() {
        Id parentRecord = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account account = new Account(Name='Test Account', BillingPostalCode='N12', recordTypeId = parentRecord);
        Test.setMock(HttpCalloutMock.class, new RestMock('N12	51.6154	-0.178479'));
        Test.startTest();
        INSERT account;
        Test.stopTest();

        account = [SELECT Council__c, IsCouncilUpdatedViaDoogle__c FROM Account WHERE Id = :account.Id];
        Assert.isNull(account.Council__c);
        Assert.isFalse(account.IsCouncilUpdatedViaDoogle__c);
    }

    @isTest
    private static void testUpdatePostCode() {
        Id parentRecord = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account account = new Account(Name='Test Account', recordTypeId = parentRecord);
        INSERT account;

        account.BillingPostalCode = 'NW1 6TS';
        Test.setMock(HttpCalloutMock.class, new RestMock('NW1 6TS	51.521556	-0.164362	Within the building of the matched address closest to the postcode mean	Cities of London and Westminster	Westminster	Regent\'s Park	Westminster 012C	Greater London	London	England		41.24314117431641	Urban major conurbation	London	E01004661'));
        Test.startTest();
        UPDATE account;
        Test.stopTest();

        account = [SELECT Council__c, IsCouncilUpdatedViaDoogle__c FROM Account WHERE Id = :account.Id];
        Assert.areEqual('Westminster', account.Council__c);
        Assert.isTrue(account.IsCouncilUpdatedViaDoogle__c);
    }

    @isTest
    private static void testInsertWithPostCode() {
        Id parentRecord = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account account = new Account(Name='Test Account', BillingPostalCode='TW1 2RS', recordTypeId = parentRecord);
        Test.setMock(HttpCalloutMock.class, new RestMock('TW1 2RS	51.452903	-0.317551	Postcode terminated prior to Gridlink initiative - last known ONS postcode grid reference	Twickenham	Richmond upon Thames	Twickenham Riverside	Richmond upon Thames 009C	Greater London	London	England		10.66619777679443	Urban major conurbation	Slough and Heathrow	E01003894'));
        Test.startTest();
        INSERT account;
        Test.stopTest();

        account = [SELECT Council__c, IsCouncilUpdatedViaDoogle__c FROM Account WHERE Id = :account.Id];
        Assert.areEqual('Richmond upon Thames', account.Council__c); // Council based on postcode
        Assert.isTrue(account.IsCouncilUpdatedViaDoogle__c);
    }

    public class RestMock implements HttpCalloutMock {
        String responseBody;

        public RestMock(String mockResponseBody) {
            this.responseBody = mockResponseBody;
        }

        public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse response = new HTTPResponse();
            response.setBody(responseBody);
            response.setStatusCode(200);
            return response;
        }
    }
}