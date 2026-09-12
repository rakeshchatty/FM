@isTest
private class InfinityFileExporterTest {

	@TestSetup
	static void makeData(){
		INSERT new InfinitySetting__c(ExternalInbox__c = 'test@test.com');

		Account parentAccount = TestDataHelper.insertAccount();
		Contact financeContact = TestDataHelper.insertContact(parentAccount.Id, 'InfinityTest');
		financeContact.Phone = financeContact.MobilePhone;
		UPDATE financeContact;

		AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :parentAccount.Id AND ContactId = :financeContact.Id];
		acr.Roles = 'Finance Contact';
		UPDATE acr;

		List<Opportunity> Opportunities = new List<Opportunity>();
		Opportunities.add(new opportunity(Name = 'Test Opp 1', CloseDate = date.today().addDays(30), StageName = 'Discovery', Estimated_Annual_Sales__c = 10000, AccountId = parentAccount.Id, Type__c = 'Inbound Phone'));
		Opportunities.add(new opportunity(Name = 'Test Opp 2', CloseDate = date.today().addDays(30), StageName = 'Discovery', Estimated_Annual_Sales__c = 10000, AccountId = parentAccount.Id, Type__c = 'Inbound Phone'));
		Opportunities.add(new opportunity(Name = 'Test Opp 3', CloseDate = date.today().addDays(30), StageName = 'Discovery', Estimated_Annual_Sales__c = 10000, AccountId = parentAccount.Id, Type__c = 'Inbound Phone'));
		INSERT Opportunities;
	}

	@isTest
	static void testInfinityFileExport() {
		Assert.areEqual(3, [SELECT Id FROM Opportunity WHERE IsSentToInfinity__c = false].size());

		Test.startTest();
		new InfinityFileExportScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(3, [SELECT Id FROM Opportunity WHERE IsSentToInfinity__c = true].size());
	}
}