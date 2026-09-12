@isTest
private class RoutingGetCollectionResultTest {

	private static final Integer JOB_ID = 1234;

	@testSetup
	static void setup() {
		TestDataHelper.insertRoutingSetting();

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round, JOB_ID);
		List<DispatchLocation__c> dispatchLocations = new List<DispatchLocation__c>();
		dispatchLocations.add(TestDataHelper.createDispatchLocation(dispatch, location));
		dispatchLocations.add(TestDataHelper.createDispatchLocation(dispatch, location));
		dispatchLocations.add(TestDataHelper.createDispatchLocation(dispatch, location));
		INSERT dispatchLocations;
	}

	@isTest
	static void getResultRouting() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock('Routing'));
		System.enqueueJob(new RoutingGetCollectionResultQueueable(JOB_ID));
		Test.stopTest();

		DailyDispatch__c dispatch = [SELECT RoutingStatus__c, RoutingPollCount__c FROM DailyDispatch__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('New', dispatch.RoutingStatus__c);
		Assert.areEqual(1, dispatch.RoutingPollCount__c);
	}

	@isTest
	static void getResultPollCountExceeded() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock('Routing'));
		System.enqueueJob(new RoutingGetCollectionResultQueueable(JOB_ID, 2));
		Test.stopTest();

		DailyDispatch__c dispatch = [SELECT RoutingStatus__c, RoutingPollCount__c FROM DailyDispatch__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('Stuck', dispatch.RoutingStatus__c);
		Assert.areEqual(2, dispatch.RoutingPollCount__c);
	}

	@isTest
	static void getResultError() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(false));
		System.enqueueJob(new RoutingGetCollectionResultQueueable(JOB_ID));
		Test.stopTest();

		DailyDispatch__c dispatch = [SELECT RoutingStatus__c, RoutingResponse__c FROM DailyDispatch__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('Error', dispatch.RoutingStatus__c);
		Assert.isTrue(dispatch.RoutingResponse__c.contains('501'));
	}

	@isTest
	static void getResultUnknownStatus() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock('Unknown Status'));
		System.enqueueJob(new RoutingGetCollectionResultQueueable(JOB_ID));
		Test.stopTest();

		DailyDispatch__c dispatch = [SELECT RoutingStatus__c, RoutingResponse__c FROM DailyDispatch__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('Error', dispatch.RoutingStatus__c);
		Assert.isTrue(dispatch.RoutingResponse__c.contains('Unknown Status'));
	}

	@isTest
	static void getResultComplete() {
		List<DispatchLocation__c> dispatchLocations = [SELECT Name FROM DispatchLocation__c LIMIT 3];
		List<RoutingResponse.ServiceLocation> serviceLocations = new List<RoutingResponse.ServiceLocation>();
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			RoutingResponse.ServiceLocation serviceLocation = new RoutingResponse.ServiceLocation();
			serviceLocation.recordID = Convert.toInteger(dispatchLocation.Name);
			serviceLocations.add(serviceLocation);
		}
		serviceLocations[0].sequence = 5;
		serviceLocations[1].sequence = 6;
		serviceLocations[2].sequence = 2;

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(serviceLocations));
		System.enqueueJob(new RoutingGetCollectionResultQueueable(JOB_ID));
		Test.stopTest();

		DailyDispatch__c dispatch = [SELECT Id, RoutingStatus__c, RoutingPollCount__c FROM DailyDispatch__c WHERE RoutingJobId__c = :JOB_ID];
		DispatchLocation__c dispatchLocation = [SELECT SequenceNumber__c FROM DispatchLocation__c WHERE Dispatch__c = :dispatch.Id ORDER BY SequenceNumber__c LIMIT 1];
		Assert.areEqual('Completed', dispatch.RoutingStatus__c);
		Assert.areEqual(1, dispatchLocation.SequenceNumber__c);
	}

	@isTest
	static void getResultCompleteCluster() {
		Account location = TestDataHelper.getLocation();
		location.StreetSegmentId__c = 'Segment 001';
		UPDATE location;

		List<DispatchLocation__c> dispatchLocations = [SELECT Name FROM DispatchLocation__c LIMIT 3];
		List<RoutingResponse.ServiceLocation> serviceLocations = new List<RoutingResponse.ServiceLocation>();
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			RoutingResponse.ServiceLocation serviceLocation = new RoutingResponse.ServiceLocation();
			serviceLocation.recordID = Convert.toInteger(dispatchLocation.Name);
			serviceLocations.add(serviceLocation);
		}
		serviceLocations[0].sequence = 5;
		serviceLocations[1].sequence = 6;
		serviceLocations[2].sequence = 2;

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(serviceLocations));
		System.enqueueJob(new RoutingGetCollectionResultQueueable(JOB_ID));
		Test.stopTest();

		DailyDispatch__c dispatch = [SELECT Id, RoutingStatus__c, RoutingPollCount__c FROM DailyDispatch__c WHERE RoutingJobId__c = :JOB_ID];
		dispatchLocations = [SELECT SequenceNumber__c FROM DispatchLocation__c WHERE Dispatch__c = :dispatch.Id];
		Assert.areEqual('Completed', dispatch.RoutingStatus__c);
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			Assert.areEqual(1, dispatchLocation.SequenceNumber__c);
		}
	}

	private class Mock implements HttpCalloutMock {

		Boolean isSuccess = true;
		String status = 'Complete';
		List<RoutingResponse.ServiceLocation> serviceLocations;

		private Mock(Boolean isSuccess) {
			this.isSuccess = isSuccess;
		}
		private Mock(String status) {
			this.status = status;
		}
		private Mock(List<RoutingResponse.ServiceLocation> serviceLocations) {
			this.serviceLocations = serviceLocations;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'text/json');

			RoutingResponse routingResponse = new RoutingResponse();
			routingResponse.jobId = JOB_ID;
			routingResponse.status = status;
			routingResponse.serviceLocations = serviceLocations;
			response.setStatusCode(isSuccess ? 200 : 501);
			response.setBody(JSON.serialize(routingResponse));
			return response;
		}
	}
}