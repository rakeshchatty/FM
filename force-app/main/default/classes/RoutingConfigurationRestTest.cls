@isTest
private class RoutingConfigurationRestTest {

	@isTest
	static void getConfigurations() {

		INSERT new MileySetting__c(IsLocationSubmissionAutoOpenEnabled__c = false, AutoOpenLocationSubmissionRadius__c = 50.0,
			IsLocationSubmissionGeofenceEnabled__c = true, GeofenceLocationSubmissionRadius__c = 100.0,
			LocationAccuracyPriority__c = 102.0, MaxLocationUpdateDelayMillis__c = 10000, MinLocationUpdateDistanceMeters__c = 200);

		RestRequest request = new RestRequest();
		RestContext.request = request;
		request.requestURI = '/services/apexrest/MileyConfiguration/';
		request.httpMethod = 'GET';

		RestResponse response = new RestResponse();
		RestContext.response = response;
		Test.startTest();
		RoutingConfigurationRest.get();
		Test.stopTest();

		Map<String, Object> responseMap = (Map<String, Object>)JSON.deserializeUntyped(response.responseBody.toString());
		Assert.isFalse((Boolean)responseMap.get('isLocationSubmissionAutoOpenEnabled'));
		Assert.isTrue((Boolean)responseMap.get('isLocationSubmissionGeofenceEnabled'));
		Assert.areEqual(50.0, (Decimal)responseMap.get('autoOpenLocationSubmissionRadius'));
		Assert.areEqual(100.0, (Decimal)responseMap.get('geofenceLocationSubmissionRadius'));
		Assert.areEqual(102, (Integer)responseMap.get('locationAccuracyPriority'));
		Assert.areEqual(10000, (Integer)responseMap.get('maxLocationUpdateDelayMillis'));
		Assert.areEqual(200, (Integer)responseMap.get('minLocationUpdateDistanceMeters'));
	}
}