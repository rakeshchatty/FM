@isTest
private class BambooEmployeeDirectorySchedulerTest {

	@isTest
	static void testSuccess() {
		Test.setMock(HttpCalloutMock.class, new MockResponse(true));

		Test.startTest();
		new BambooEmployeeDirectoryScheduler().execute(null);
		Test.stopTest();

		Integer countDrivers = [SELECT COUNT() FROM Driver__c];
		System.assertEquals(2, countDrivers, 'Two driver records should be created');
	}

	@isTest
	static void testError() {
		Test.setMock(HttpCalloutMock.class, new MockResponse(false));

		Test.startTest();
		new BambooEmployeeDirectoryScheduler().execute(null);
		Test.stopTest();

		Integer countDrivers = [SELECT COUNT() FROM Driver__c];
		System.assertEquals(0, countDrivers, 'No driver records should be created when HTTP call fails');
	}

	// Mock for successful callout
	private class MockResponse implements HttpCalloutMock {
		private Boolean isSuccess;

		private MockResponse(Boolean isSuccess) {
			this.isSuccess = isSuccess;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse response = new HTTPResponse();
			if (!isSuccess) {
				response.setStatusCode(500);
				return response;
			}

			response.setStatusCode(200);
			String body = '{'
				+ '"data": ['
				+ '  {"eeid":"101","employeeNumber":"E101","status":"Active","firstName":"John","lastName":"Doe","firstNameLastName":"John Doe","jobInformationJobTitle":"Driver","customField4416":"Drivers"},'
				+ '  {"eeid":"102","employeeNumber":"E102","status":"InActive","firstName":"Apple","lastName":"Mac","firstNameLastName":"Apple Mac","jobInformationJobTitle":"Driver","customField4416":"Drivers"},'
				+ '  {"eeid":"103","employeeNumber":"E103","status":"Active","firstName":"Jane","lastName":"Smith","firstNameLastName":"Jane Smith","jobInformationJobTitle":"Mechanic","customField4416":"NotDrivers"}'
				+ '],'
				+ '"pagination": {"next_page": null, "current_page": 1}'
				+ '}';
			response.setBody(body);
			return response;
		}
	}
}