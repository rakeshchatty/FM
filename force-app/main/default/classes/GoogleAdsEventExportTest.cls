@isTest
private class GoogleAdsEventExportTest {

	@TestSetup
	static void makeData() {
		INSERT new GoogleAdsSetting__c(ExternalInbox__c = 'test@test.com', LeadStatusToSkip__c = 'Closed. Existing customer, Closed. Not Relevant');

		INSERT new Lead(FirstName = 'Test', LastName = 'Account', Company = 'Test Company', Email = 'test@mail.com', MobilePhone = '090000000123', LeadSource = 'Got a leaflet', Services_wanted__c = 'Reporting and Data');

		Account parentAccount = TestDataHelper.insertAccount();
		Account locationAccount = TestDataHelper.insertLocation(parentAccount.Id, Null);

		Order order = TestDataHelper.insertOrder(locationAccount.Id);
		order.Status = 'Confirmed';
		UPDATE order;

		Opportunity opportunity = new opportunity(Name = 'Test Opp', CloseDate = date.today().addDays(30), StageName = 'Discovery', Estimated_Annual_Sales__c = 10000, AccountId = locationAccount.Id, Services__c = 'Scheduled Waste and Recycling Collections');
		INSERT opportunity;

		opportunity.StageName = 'Handed Over';
		UPDATE opportunity;
	}

	@isTest
	static void testGoogleAdsEventExport() {
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'New'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'New'].size());

		Test.startTest();
		new GoogleAdsEventExportScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'New'].size());
		Assert.areEqual(0, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'New'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'Processed'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'Processed'].size());
	}

	@isTest
	static void testNewOrderOnAccount() {
		Order order = TestDataHelper.insertOrder([SELECT Id FROM Account WHERE Name ='Location'].Id);
		order.Status = 'Confirmed';
		UPDATE order;

		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'New'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'New'].size());

		Test.startTest();
		new GoogleAdsEventExportScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'New'].size());
		Assert.areEqual(0, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'New'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'Processed'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'Processed'].size());
	}

	@isTest
	static void testScheduledDeletion() {
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'New'].size());
		Assert.areEqual(1, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'New'].size());

		Test.setCreatedDate([SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity' AND Status__c = 'New'].Id, Datetime.now().addDays(-95));
		Test.setCreatedDate([SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order' AND Status__c = 'New'].Id, Datetime.now().addDays(-95));

		new GoogleAdsEventExportScheduler().execute(null);

		Test.startTest();
		new DeleteGoogleAdsEventScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Opportunity'].size());
		Assert.areEqual(0, [SELECT Id FROM GoogleAdsEvent__c WHERE Type__c = 'Order'].size());
	}
}