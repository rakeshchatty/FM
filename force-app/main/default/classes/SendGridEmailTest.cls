@isTest
public class SendGridEmailTest {

	@testSetup
	private static void testSetup() {
		TestDataHelper.insertSendGridSetting();
	}

	private static testmethod void sendGridTest() {

		SendGridEmail.Input input = new SendGridEmail.Input();
		input.templateId = 'templateId123';
		input.toAddress = new List<String>{'toAddress@toAddress.com'};
		input.toName = new List<String>{'toName'};
		input.var01 = '1';
		input.var02 = '2';
		input.var03 = '3';
		input.var04 = '4';
		input.var05 = '5';
		input.var06 = '6';
		input.var07 = '7';
		input.var08 = '8';
		input.var09 = '9';
		input.var10 = '10';
		input.var11 = '11';
		input.var12 = '12';
		input.var13 = '13';
		input.var14 = '14';
		input.var15 = '15';
		input.var16 = '16';
		input.var17 = '17';
		input.var18 = '18';
		input.var19 = '19';
		input.var20 = '20';
		input.collection.add(UnitTest.testAccount());

		Test.setMock(HttpCalloutMock.class, new SendGridResponseMock());

		Test.startTest();
		new SendGridEmail(new List<SendGridEmail.Input>{input}).send();
		Test.stopTest();
	}

	private class SendGridResponseMock implements HttpCalloutMock {

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse res = new HTTPResponse();
			res.setHeader('Content-Type', 'text/json');
			res.setStatusCode(200);
			return res;
		}
	}

	@isTest static void testHubSpotEvent() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Round__c round = TestDataHelper.insertRound();
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Product2 product = TestDataHelper.insertProduct('Product1', 'FM001', 'Collection');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		TestDataHelper.insertSchedule(location, round, supplier, supplierProduct, '10:00');
		TestDataHelper.insertSchedule(location, round, supplier, supplierProduct, '11:00');

		List<sObject> aggregators = [SELECT SupplierProductName__c, Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c FROM CollectionAggregator__c];

		SendGridEmail.Input input = new SendGridEmail.Input();
		input.templateId = 'templateId123';
		input.toAddress = new List<String>{'toAddress@toAddress.com'};
		input.toName = new List<String>{'toName'};
		input.accountId = 'TestAccoundId';
		input.eventType = 'TestEventType';
		input.var01 = '1';
		input.var02 = '2';
		input.var03 = '3';
		input.var04 = '4';
		input.var05 = '5';
		input.collection.addAll(aggregators);

		Test.setMock(HttpCalloutMock.class, new SendGridResponseMock());

		Test.startTest();
		new SendGridEmail(new List<SendGridEmail.Input>{input}).send();
		Test.stopTest();
	}
}