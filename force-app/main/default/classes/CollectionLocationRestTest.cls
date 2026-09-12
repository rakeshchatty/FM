@isTest
private class CollectionLocationRestTest {

	private static final Integer JOB_ID = 1234;

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		List<DispatchLocation__c> dispatchLocations = new List<DispatchLocation__c>();
		dispatchLocations.add(TestDataHelper.createDispatchLocation(dispatch, location));
		dispatchLocations[0].SequenceNumber__c = 1;
		dispatchLocations.add(TestDataHelper.createDispatchLocation(dispatch, location));
		dispatchLocations[1].SequenceNumber__c = 2;
		dispatchLocations.add(TestDataHelper.createDispatchLocation(dispatch, location));
		INSERT dispatchLocations;
		TestDataHelper.insertWaypoint(location, dispatch, dispatchLocations[0]);
	}

	static RestRequest setRequest() {
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c];
        RestRequest request = new RestRequest();
        RestContext.request = request;
        request.requestURI = '/services/apexrest/Locations/' + dispatch.Id;
		return request;
	}

	@isTest
	static void getLocations() {
		RestRequest request = setRequest();
		request.httpMethod = 'GET';

		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CollectionLocationRest.get();
		Test.stopTest();

		Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Assert.areEqual(2, ((List<Object>)responseMap.get('locations')).size());
		Assert.areEqual(1, ((List<Object>)responseMap.get('additionalLocations')).size());
	}

	@isTest
	static void getLocation() {
		RestRequest request = setRequest();
		request.httpMethod = 'GET';
		request.params.put('id', String.join(new Map<Id, DispatchLocation__c>([SELECT Id FROM DispatchLocation__c]).keySet(), ','));

		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CollectionLocationRest.get();
		Test.stopTest();

		List<Object> responseList = (List<Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Assert.areEqual(3, responseList.size());
	}

	@isTest
	static void submit() {
		CollectionLocationRest.Request requestBody = new CollectionLocationRest.Request();
		requestBody.locations = new List<Id>(new Map<Id, DispatchLocation__c>([SELECT Id FROM DispatchLocation__c]).keySet());
		requestBody.status = 'Completed';

		RestRequest request = setRequest();
		request.httpMethod = 'PATCH';
		request.requestBody = Blob.valueOf(JSON.serialize(requestBody));

		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		CollectionLocationRest.submit();
		Test.stopTest();

		Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Assert.areEqual(2, ((List<Object>)responseMap.get('locations')).size());
		Assert.areEqual(1, ((List<Object>)responseMap.get('additionalLocations')).size());

		List<DispatchLocation__c> dispatchLocations = [SELECT Status__c FROM DispatchLocation__c];
		Assert.areEqual(3, dispatchLocations.size());
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			Assert.areEqual('Completed', dispatchLocation.Status__c);
		}
	}
}