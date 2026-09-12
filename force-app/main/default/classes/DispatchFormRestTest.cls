@isTest
private class DispatchFormRestTest {

	private static final Integer JOB_ID = 1234;

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		TestDataHelper.insertVehicle('ABC XYZ');
	}

	@isTest
	static void get() {
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c];
		RestRequest request = new RestRequest();
		RestContext.request = request;
		request.requestURI = '/services/apexrest/DispatchForm/' + dispatch.Id;
		request.httpMethod = 'GET';

		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		DispatchFormRest.get();
		Test.stopTest();

		Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Assert.areEqual(1, ((List<Object>)responseMap.get('vehicles')).size());
		Assert.areEqual(false, (Boolean)responseMap.get('isStarted'));
	}

	@isTest
	static void getWithPreviousDispatch() {
		Round__c round = [SELECT Id FROM Round__c];
		DailyDispatch__c dispatchYesterday = new DailyDispatch__c(RoundId__c = round.Id, Name = 'Yesterday');
		dispatchYesterday.CreatedDate = System.today().addDays(-1);
		INSERT dispatchYesterday;

		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c WHERE Id != :dispatchYesterday.Id];
		RestRequest request = new RestRequest();
		RestContext.request = request;
		request.requestURI = '/services/apexrest/DispatchForm/' + dispatch.Id;
		request.httpMethod = 'GET';

		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		DispatchFormRest.get();
		Test.stopTest();

		Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Assert.areEqual(1, ((List<Object>)responseMap.get('vehicles')).size());
		Assert.areEqual(false, (Boolean)responseMap.get('isStarted'));
	}
}