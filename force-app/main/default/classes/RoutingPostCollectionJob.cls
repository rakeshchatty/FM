public without sharing class RoutingPostCollectionJob extends RoutingPostJob {

	private Id dispatchId;

	public RoutingPostCollectionJob(Id dispatchId) {
		this.dispatchId = dispatchId;
	}

	protected override RoutingRequest createRequest() {
		DailyDispatch__c dispatch = [SELECT RoundId__r.Round_Type__c, RoundId__r.StartDepot__c, RoundId__r.StartDepot__r.Index__c, RoundId__r.EndDepot__c, RoundId__r.EndDepot__r.Index__c, RoundId__r.StartTime__c
			FROM DailyDispatch__c WHERE Id = :dispatchId];

		RoutingParameterOverride__mdt overrides = RoutingParameterOverride.get('Collection' + dispatch.RoundId__r.Round_Type__c);
		if (String.isNotBlank(dispatch.RoundId__r.StartTime__c)) {
			overrides.StartTime__c = dispatch.RoundId__r.StartTime__c;
		}
		overrides.StartDepotIndex__c = Convert.toInteger(dispatch.RoundId__r.StartDepot__r.Index__c);
		overrides.EndDepotIndex__c = Convert.toInteger(dispatch.RoundId__r.EndDepot__r.Index__c);

		List<Depot__c> depots = [SELECT Index__c, Name, Address__Street__s, Address__City__s, Address__PostalCode__s, Coordinates__Latitude__s, Coordinates__Longitude__s
			FROM Depot__c WHERE Id IN (:dispatch.RoundId__r.StartDepot__c, :dispatch.RoundId__r.EndDepot__c)];

		List<DispatchLocation__c> locations = [SELECT Name, Location__r.Name, Location__r.BillingStreetLineSingle__c, Location__r.BillingPostalCode,
			Location__r.BillingLatitude, Location__r.BillingLongitude, ServiceTime__c, EarliestArrival__c, LatestArrival__c
			FROM DispatchLocation__c WHERE Dispatch__c = :dispatchId  AND Location__r.IsLive__c = true];

		return new RoutingRequestCollection(overrides, depots, locations);
	}

	protected override void updateJobError(String status, String message) {
		updateJob(new DailyDispatch__c(RoutingStatus__c = status, RoutingResponse__c = message));
	}

	protected override void processResult(RoutingResponse routingResponse) {
		updateJob(new DailyDispatch__c(RoutingJobId__c = routingResponse.jobId, RoutingStatus__c = 'In Progress',
			RoutingPollCount__c = 0, RoutingResponse__c = null, RoutingSummary__c = null));

		System.enqueueJob(new RoutingGetCollectionResultQueueable(routingResponse.jobId), 1);
	}

	private void updateJob(DailyDispatch__c dispatch) {
		dispatch.Id = dispatchId;
		UPDATE dispatch;
	}
}