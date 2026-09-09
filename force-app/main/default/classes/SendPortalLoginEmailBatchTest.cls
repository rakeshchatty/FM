@isTest
private class SendPortalLoginEmailBatchTest {

	@isTest
	static void sendEmail() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.createLocation(parent.Id, null);
		location.Enqix_Start_Date__c = System.today() - 1;
		INSERT location;
		Contact contact = TestDataHelper.insertContact(parent.Id, 'FirstMile');
		TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact;Finance Contact');

		Test.startTest();
		new SendPortalLoginEmailScheduler().execute(null);
		Test.stopTest();

		contact = [SELECT PortalLoginEmailSent__c FROM Contact WHERE Id = :contact.Id];
		Assert.isTrue(contact.PortalLoginEmailSent__c);
	}
}