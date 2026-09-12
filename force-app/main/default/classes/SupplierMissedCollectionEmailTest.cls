@isTest
private class SupplierMissedCollectionEmailTest {

	@TestSetup
	static void setupTestData(){
		Product2 product = TestDataHelper.insertProduct('(P) Test Product 1', 'P0001', 'Collection');
		Suppliers__c supplier = TestDataHelper.insertSupplier('Test Supplier 1');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		Round__c round = TestDataHelper.insertRound();
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		List<Schedule__c> schedules = new List<Schedule__c>();
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '08:00'));
		schedules.add(TestDataHelper.createSchedule(location, round, supplier, supplierProduct, '09:00'));
		INSERT schedules;

		INSERT new DailyDispatch__c(RoundId__c = round.Id, Name = 'Test dispatch');

		Case missedCase = new Case(
			RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Missed Collection').getRecordTypeId(),
			Type = 'Missed Collection',
			AccountId = location.Id,
			Location__c = location.Id,
			Sub_Type__c = 'Collection Round Service Missed'
		);
		INSERT missedCase;

		List<Missed_Collection__c> missedCollections = new List<Missed_Collection__c>();
		for (Schedule__c schedule : [SELECT Id FROM Schedule__c WHERE Location__c = :location.Id AND Days__c = :System.now().format('EEEE')]) {
			missedCollections.add(new Missed_Collection__c(Case__c = missedCase.Id, Collection_Schedule__c = schedule.Id));
		}
		INSERT missedCollections;

		User testUser = [SELECT Id FROM User WHERE IsActive = TRUE LIMIT 1];
		System.runAs(testUser) {
			EmailTemplate emailTemplate = new EmailTemplate(
				Name = 'Test Email Template',
				DeveloperName = 'SupplierMissedCollection',
				HtmlValue = 'Hello {{1}},<br/>Your missed collections:<br/>{{0}}<br/>Location: {{2}}',
				Subject = 'Missed Collections Notification',
				TemplateType ='custom',
				FolderId = UserInfo.getUserId() // Assign to a valid folder

			);
			INSERT emailTemplate;
		}
	}

	@isTest
	static void testSendSupplierEmails() {
		// Fetch a test case
		Case testCase = [SELECT Id FROM Case LIMIT 1];

		Test.startTest();
		// Call the method to test
		SupplierMissedCollectionEmail.send(new list<Id>{testCase.Id});
		Test.stopTest();

		// Verify that an email was sent
		List<EmailMessage> sentEmails = [SELECT Id, Subject FROM EmailMessage WHERE ParentId = :testCase.Id];
		System.assert(!sentEmails.isEmpty(), 'Emails should have been sent');
		System.assertEquals('Missed Collections Notification', sentEmails[0].Subject, 'Subject should match');
	}
}