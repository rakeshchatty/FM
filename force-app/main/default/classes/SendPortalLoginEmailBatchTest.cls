@isTest
private class SendPortalLoginEmailBatchTest {

	@isTest
	static void sendEmail() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.createLocation(parent.Id, null);
		location.Enqix_Start_Date__c = System.today() - 2;
		INSERT location;
		Contact contact1 = TestDataHelper.insertContact(parent.Id, 'FirstMile');
		TestDataHelper.insertAccountContactRelation(location.Id, contact1.Id, 'Service Contact;Finance Contact');

		Test.startTest();
		new SendPortalLoginEmailScheduler().execute(null);
		Test.stopTest();

		contact1 = [SELECT PortalLoginEmailSentDate__c FROM Contact WHERE Id = :contact1.Id];
		Assert.isNotNull(contact1.PortalLoginEmailSentDate__c);
	}
}