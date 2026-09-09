@isTest
private class LogDeleteBatchTest {

	@isTest
	private static void deleteOlderLogs() {
		Test.startTest();
		LogDeleteBatch.deleteOlderLogs();
		Test.stopTest();
	}
}