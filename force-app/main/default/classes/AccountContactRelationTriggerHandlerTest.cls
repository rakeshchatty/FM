@isTest
private class AccountContactRelationTriggerHandlerTest {
	@TestSetup
	static void testSetup() {
		Account account = TestDataHelper.insertAccount();
		Test.startTest();
		Contact contact = TestDataHelper.insertContact(account.Id, 'FirstMile');
		Test.stopTest();
	}

	@isTest
	static void validateFinanceContact() {
		AccountContactRelation acr = [SELECT Id FROM AccountContactRelation LIMIT 1];
		try {
			acr.Roles = 'Other Role';
			UPDATE acr;
		} catch (exception e) {
			Assert.areEqual('Finance Contact', [SELECT Roles FROM AccountContactRelation LIMIT 1].Roles, 'Expected role to be Finace Contact.');
			System.debug('e.getMessage() :: ' + e.getMessage());
            Assert.isTrue(e.getMessage().contains('Finance Contact role is required.'), 'Prevent ACR update');
		}

		try {
			DELETE acr;
		} catch(Exception e) {
			Assert.areEqual(1, [SELECT Roles FROM AccountContactRelation LIMIT 1].size(), 'Expected Finace Contact not to be deleted.');
			Assert.isTrue(e.getMessage().contains('Finance contact is required on this account'), 'Prevent ACR deletion.');
		}

		try {
			DELETE [SELECT Id FROM Contact];
		} catch(exception e) {
			Assert.isTrue(e.getMessage().contains('Finance contact is required on live account'), 'Prevent Contact Deletion.');
		}
	}
}