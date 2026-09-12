@isTest
private class LegalEntityTest {

	@isTest
	static void get() {
		LegalEntity__c entity = TestDataHelper.insertLegalEntity('Test Entity');
		LegalEntity.get(entity.Id);
	}
}