@isTest
private class InfinitySftpEmailServiceTest {

	@TestSetup
	static void makeData(){
		Account parentAccount = TestDataHelper.insertAccount();
		Account locationAccount = TestDataHelper.insertLocation(parentAccount.Id, null);

		INSERT new Opportunity(Name = 'Test Opp', CloseDate = date.today().addDays(30), StageName = 'Discovery', Estimated_Annual_Sales__c = 10000, AccountId = locationAccount.Id, Type__c = 'Inbound Phone');
	}

	@isTest
	static void emailWithAttachment() {
		Messaging.InboundEmail email = new Messaging.InboundEmail();
		email.subject = 'Test Email';

		Opportunity opp = [SELECT Id FROM Opportunity];
		Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
		binaryAttachment.fileName = 'FileFromInfinity.csv';
		binaryAttachment.body = Blob.valueOf('Channel, Trigger Title, Campaign, Channel Type, HTTP URL, Keyword\n'
									+ 'Paid Search, ' + opp.Id + ', Generic - Search - Waste, ppc, https://www.thefirstmile.co.uk/, waste collection london');
		email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>{binaryAttachment};

		Test.startTest();
		new InfinitySftpEmailService().handleInboundEmail(email, new Messaging.InboundEnvelope());
		Test.stopTest();

		opp = [SELECT Id, gaconnector_First_Click_Channel__c, gaconnector_First_Click_Campaign__c, gaconnector_First_Click_Term__c,
						gaconnector_First_Click_Medium__c, gaconnector_First_Click_Landing_Page__c FROM Opportunity WHERE Id = :opp.Id];
		Assert.areEqual('Paid Search', opp.gaconnector_First_Click_Channel__c);
		Assert.areEqual('Generic - Search - Waste', opp.gaconnector_First_Click_Campaign__c);
		Assert.areEqual('waste collection london', opp.gaconnector_First_Click_Term__c);
		Assert.areEqual('cpc', opp.gaconnector_First_Click_Medium__c);
		Assert.areEqual('https://www.thefirstmile.co.uk/', opp.gaconnector_First_Click_Landing_Page__c);
	}
}