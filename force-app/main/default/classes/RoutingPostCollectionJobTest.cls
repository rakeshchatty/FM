@isTest
private class RoutingPostCollectionJobTest {

	private static final Integer JOB_ID = 1234;

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);
	}

	@isTest
	static void postJobs() {
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c];
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Database.executebatch(new RoutingPostCollectionJobBatch(new Set<Id>{dispatch.Id}), 1);
		Test.stopTest();

		Assert.areEqual(JOB_ID, [SELECT RoutingJobId__c FROM DailyDispatch__c].RoutingJobId__c);
	}

	@isTest
	static void postJobError() {
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c];

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(false));
		RoutingPostCollectionJobInvoke.sequence(new List<List<Id>>{new List<Id>{dispatch.Id}});
		Test.stopTest();

		dispatch = [SELECT RoutingJobId__c FROM DailyDispatch__c];
		Assert.areEqual(null, dispatch.RoutingJobId__c);
	}

    private class Mock implements HttpCalloutMock {

		Boolean isSuccess = true;
		private Mock(Boolean isSuccess) {
			this.isSuccess = isSuccess;
		}

		public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'text/json');

			RoutingResponse routingResponse = new RoutingResponse();
			routingResponse.jobId = JOB_ID;
			response.setStatusCode(isSuccess ? 202 : 501);
			response.setBody(JSON.serialize(routingResponse));
            return response;
        }
    }
}