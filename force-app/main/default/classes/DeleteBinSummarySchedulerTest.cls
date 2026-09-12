@isTest
private class DeleteBinSummarySchedulerTest {

	@isTest
	static void test(){
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Date createdDate = System.today() - 367;
		String month = String.valueOf('0' + CreatedDate.month()).right(2);
		String year = String.valueOf(CreatedDate.year());
		String key1 = location.Id + '-' + 'GEN1100' + '-' + year + '-' + month;
		String key2 = location.Id + '-' + 'GEN660' + '-' + year + '-' + month;

		BinSummary__c bin1 = new BinSummary__c(Location__c = location.Id, Month__c = month, CategoryCode__c = 'GEN1100', Year__c = year, CreatedDate = createdDate, Key__c = key1);
		BinSummary__c bin2 = new BinSummary__c(Location__c = location.Id, Month__c = month, CategoryCode__c = 'GEN660', Year__c = year, CreatedDate = createdDate, Key__c = key2);
		INSERT new List<BinSummary__c>{bin1, bin2};

		Assert.areEqual(2, [SELECT Id FROM BinSummary__c].size());

		Test.startTest();
		new DeleteBinSummaryScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(0, [SELECT Id FROM BinSummary__c].size());
	}
}