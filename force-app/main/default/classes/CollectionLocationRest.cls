@RestResource(urlMapping='/Locations/*')
global without sharing class CollectionLocationRest {

	@HttpGet
	global static void get() {
		String locationIds = RestContext.request.params?.get('id');
		if (String.isBlank(locationIds)) {
			getAll();
		} else {
			getById(locationIds.split(','));
		}
	}

	@HttpPatch
	global static void submit() {
		Request request = (Request)JSON.deserialize(RestContext.request.requestBody.toString(), Request.class);

		DateTime now = System.now();
		List<DispatchLocation__c> dispatchLocations = new List<DispatchLocation__c>();
		for (Id dispatchLocationId : request.locations) {
			dispatchLocations.add(new DispatchLocation__c(Id = dispatchLocationId, Status__c = request.status,
				SubmittedFrom__Longitude__s = request.longitude, SubmittedFrom__Latitude__s = request.latitude, SubmittedAt__c = now));
		}
		UPDATE dispatchLocations;

		getAll();
	}

	private static void getAll() {
		String requestURI = RestContext.request.requestURI;
		String dispatchId = requestURI.substring(requestURI.lastIndexOf('/') + 1);

		List<DispatchLocation__c> dispatchLocations = [SELECT SequenceNumber__c, Status__c, Type__c, IsBinCollection__c, IsInternalCollection__c, Time__c,
			Location__r.Name, Location__r.CollectionPriority__c, Location__r.Comments_c__c,
			Location__r.BillingLatitude, Location__r.BillingLongitude, Location__r.BillingStreet, Location__r.BillingCity, Location__r.BillingPostalCode, Location__r.BillingCountry,
			(SELECT Supplier_Product_Name__c, Is_bin_collection__c, Collection_Quantity__c FROM CollectionWaypoints__r)
			FROM DispatchLocation__c WHERE Dispatch__c = :dispatchId AND Location__r.IsLive__c = true
			ORDER BY SequenceNumber__c, Time__c, Location__c];

		Map<Decimal, List<DispatchLocation__c>> locationBySequenceMap = new Map<Decimal, List<DispatchLocation__c>>();
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			if (locationBySequenceMap.containsKey(dispatchLocation.SequenceNumber__c)) {
				locationBySequenceMap.get(dispatchLocation.SequenceNumber__c).add(dispatchLocation);
			} else {
				locationBySequenceMap.put(dispatchLocation.SequenceNumber__c, new List<DispatchLocation__c>{dispatchLocation});
			}
		}

		List<Decimal> sequenceNumbers = new List<Decimal>(locationBySequenceMap.keySet());
		sequenceNumbers.sort();

		Boolean hasNullSequence = !sequenceNumbers.isEmpty() && sequenceNumbers[0] == null;
		if (hasNullSequence) {
			sequenceNumbers.remove(0);
		}

		List<CollectionLocation> locations = new List<CollectionLocation>();
		for (Decimal sequenceNumber : sequenceNumbers) {
			dispatchLocations = locationBySequenceMap.get(sequenceNumber);
			locations.add(new CollectionLocation(dispatchLocations));
		}

		List<CollectionLocation> additionalLocations = new List<CollectionLocation>();
		if (hasNullSequence) {
			for (DispatchLocation__c dispatchLocation : locationBySequenceMap.get(null)) {
				additionalLocations.add(new CollectionLocation(dispatchLocation));
			}
		}

		DailyDispatch__c dispatch = [SELECT RoundId__r.StartDepot__r.Name, RoundId__r.StartDepot__r.Coordinates__Longitude__s, RoundId__r.StartDepot__r.Coordinates__Latitude__s,
			RoundId__r.EndDepot__r.Name, RoundId__r.EndDepot__r.Coordinates__Longitude__s, RoundId__r.EndDepot__r.Coordinates__Latitude__s
			FROM DailyDispatch__c WHERE Id = :dispatchId];
		List<Depot> depots = new List<Depot>{new Depot(dispatch.RoundId__r.StartDepot__r, true), new Depot(dispatch.RoundId__r.EndDepot__r, false)};

		RestResponse response = RestContext.response;
		response.addHeader('Content-Type', 'application/json');
		response.responseBody = Blob.valueOf(JSON.serialize(new Map<String, Object>{'locations' => locations, 'additionalLocations' => additionalLocations, 'depots' => depots}));
	}

	private static void getById(List<String> dispatchLocationIds) {
		List<DispatchLocation__c> dispatchLocations = [SELECT SequenceNumber__c, Status__c, Type__c, IsBinCollection__c, IsInternalCollection__c, Time__c,
			Location__r.Name, Location__r.CollectionPriority__c, Location__r.Comments_c__c,
			Location__r.BillingLatitude, Location__r.BillingLongitude, Location__r.BillingStreet, Location__r.BillingCity, Location__r.BillingPostalCode, Location__r.BillingCountry,
			(SELECT Supplier_Product_Name__c, Is_bin_collection__c, Collection_Quantity__c FROM CollectionWaypoints__r)
			FROM DispatchLocation__c WHERE Id = :dispatchLocationIds
			ORDER BY SequenceNumber__c, Time__c, Location__c];

		List<CollectionLocation> locations = new List<CollectionLocation>();
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			locations.add(new CollectionLocation(dispatchLocation));
		}

		RestResponse response = RestContext.response;
		response.addHeader('Content-Type', 'application/json');
		response.responseBody = Blob.valueOf(JSON.serialize(locations));
	}

	@TestVisible
	private class Request {
		@TestVisible private List<String> locations;
		@TestVisible private String status;
		@TestVisible private Decimal longitude;
		@TestVisible private Decimal latitude;
	}

	private class Depot {
		private transient Depot__c depot;
		private transient Boolean isStart;

		private Depot(Depot__c depot, Boolean isStart) {
			this.depot = depot;
			this.isStart = isStart;
		}

		private String name { get { return depot.Name; } }
		private String type { get { return isStart ? 'Start' : 'End'; } }
		private Decimal longitude { get { return depot.Coordinates__Longitude__s; } }
		private Decimal latitude { get { return depot.Coordinates__Latitude__s; } }
	}
}