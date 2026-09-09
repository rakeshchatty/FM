@isTest
private class NewLocationControllerTest {

	@isTest static void test_method_one() {
		Test.setMock(HttpCalloutMock.class, new DoogalTest.RestMock('TW1 2RS	51.452903	-0.317551	Postcode terminated prior to Gridlink initiative - last known ONS postcode grid reference	Twickenham	Richmond upon Thames	Twickenham Riverside	Richmond upon Thames 009C	Greater London	London	England		10.66619777679443	Urban major conurbation	Slough and Heathrow	E01003894'));
		Account a = new Account();
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		a.Name = 'test';
		a.BillingCity = 'city';
		a.BillingStreet = 'street';
		a.BillingPostalCode = '12345';
		a.BillingCountry = 'United Kingdom';
		a.BillingState = null;
		a.Price_Book__c = Test.getStandardPricebookId();
		insert a;

		Account b = new Account();
		b.Name = 'test3';
		b.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		b.BillingCity = 'city';
		b.BillingStreet = 'street';
		b.BillingPostalCode = '12345';
		b.BillingCountry = 'United Kingdom';
		b.Price_Book__c = Test.getStandardPricebookId();
		b.BillingState = null;
		insert b;
		
		Opportunity opp = new Opportunity();
		opp.Name = 'test opp';
		opp.AccountId = a.Id;
		opp.CloseDate = System.today() + 10;
		opp.Estimated_Annual_Sales__c = 100;
		opp.StageName = 'DM confirmed - no response';
        opp.Services__c = 'Scheduled Waste and Recycling Collections';
		insert opp;

		Opportunity opp2 = new Opportunity();
		opp2.Name = 'test opp';
		opp2.AccountId = b.Id;
		opp2.CloseDate = System.today() + 10;
		opp2.Estimated_Annual_Sales__c = 100;
		opp2.StageName = 'DM confirmed - no response';
        opp2.Services__c = 'Scheduled Waste and Recycling Collections';
		insert opp2;

		List<string> fields2 = new List<string>();
		fields2.add('test4');

		List<string> fields = new List<string>();
		fields.add('test2');
		fields.add('street2');
		fields.add('city2');
		fields.add('12344');
		fields.add(null);
		fields.add('United Kingdom');

		NewLocationController.createLocationController(opp.Id, fields2);
		NewLocationController.createLocationWithFields(opp2.Id, fields);
		NewLocationController.getParentLocName(opp.Id);
	}

	
}