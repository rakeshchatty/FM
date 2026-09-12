@isTest
private class NextAdvanceInvoiceDateBatchTest {

	@isTest
	private static void test() {
		Account parent = TestDataHelper.createAccount();
		parent.MonthsInvoicedInAdvance__c = '3';
		parent.NextAdvanceInvoiceDate__c = Date.newInstance(2026, 07, 01);
		INSERT parent;

		Test.startTest();
		Database.executeBatch(new NextAdvanceInvoiceDateBatch(parent.NextAdvanceInvoiceDate__c));
		Test.stopTest();

		Assert.areEqual(parent.NextAdvanceInvoiceDate__c.addMonths(3), [SELECT NextAdvanceInvoiceDate__c FROM Account WHERE Id = :parent.Id].NextAdvanceInvoiceDate__c);
	}
}