@RestResource(urlMapping='/MileyConfiguration/*')
global without sharing class RoutingConfigurationRest {

	@HttpGet
	global static void get() {
		MileySetting__c settings = MileySetting__c.getOrgDefaults();
		RestResponse response = RestContext.response;
		response.addHeader('Content-Type', 'application/json');
		response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{
			'isLocationSubmissionAutoOpenEnabled' => settings.IsLocationSubmissionAutoOpenEnabled__c,
			'autoOpenLocationSubmissionRadius' => settings.AutoOpenLocationSubmissionRadius__c,
			'isLocationSubmissionGeofenceEnabled' => settings.IsLocationSubmissionGeofenceEnabled__c,
			'geofenceLocationSubmissionRadius' => settings.GeofenceLocationSubmissionRadius__c,
			'collectionExceptions' => toOptions([SELECT Id, Label FROM CollectionExceptions__mdt]),
			'locationAccuracyPriority' => (Integer)settings.LocationAccuracyPriority__c,
			'maxLocationUpdateDelayMillis' => (Integer)settings.MaxLocationUpdateDelayMillis__c,
			'minLocationUpdateDistanceMeters' => (Integer)settings.MinLocationUpdateDistanceMeters__c
		}));
	}

	private static List<Option> toOptions(List<sObject> metadataRecords) {
		List<Option> options = new List<Option>();
		for (sObject metadataRecord : metadataRecords) {
			options.add(new Option((Id)metadataRecord.get('Id'), (String)metadataRecord.get('Label')));
		}
		return options;
	}

	private class Option {
		private String id;
		private String label;

		private Option(Id id, String label) {
			this.id = id;
			this.label = label;
		}
	}
}