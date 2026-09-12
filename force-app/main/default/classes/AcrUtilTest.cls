@isTest
private class AcrUtilTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Contact contact = TestDataHelper.insertContact(parent.Id, 'SomeName');
		TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');
	}

	@isTest
	static void getLatestServiceContactForPhone() {
		Account location = [SELECT Id FROM Account WHERE RecordType.Id = :AccountUtil.RECORDTYPEID_LOCATION];
		Contact contact = AcrUtil.getLatestServiceContactForPhone(location.Id);
		Assert.areEqual('test SomeName', contact.Name);
	}

	@isTest
	static void getFinanceContactRelation() {
		Account parent = [SELECT Id FROM Account WHERE RecordType.Id = :AccountUtil.RECORDTYPEID_PARENT];
		Contact contact = [SELECT Id, Email FROM Contact WHERE AccountId = :parent.Id];

		List<AccountContactRelation> acrs = AcrUtil.getFinanceContactRelation(new Set<Id>{parent.Id});
		Assert.areEqual(1, acrs.size());
		Assert.areEqual(contact.Email, acrs[0].Contact.Email);

		contact.Preferences__c = 'No Emails';
		UPDATE contact;
		acrs = AcrUtil.getFinanceContactRelation(new Set<Id>{parent.Id});
		Assert.areEqual(0, acrs.size());
	}

	@isTest
	static void noServiceContact() {
		Account parent = [SELECT Id FROM Account WHERE RecordType.Id = :AccountUtil.RECORDTYPEID_PARENT];
		try {
			Contact contact = AcrUtil.getLatestServiceContactForPhone(parent.Id);
			Assert.fail('An exception was expected');
		} catch (AcrUtil.NoAccountRoleException e) {}
	}
}