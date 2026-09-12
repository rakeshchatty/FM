public without sharing class RoutingGetCollectionResult extends RoutingGetResult  {

	public RoutingGetCollectionResult(Integer jobId, Integer pollCount) {
		super(jobId, pollCount);
	}

	protected override void enqueue() {
		updateJob(new DailyDispatch__c());

		if (Test.isRunningTest()) {return;} else {System.enqueueJob(new RoutingGetCollectionResultQueueable(jobId, ++pollCount), 1);}
	}

	protected override void updateJobError(String status, String message) {
		updateJob(new DailyDispatch__c(RoutingStatus__c = status, RoutingResponse__c = message));
	}

	protected override void processResult(RoutingResponse routingResponse) {
		Map<Integer, DispatchLocation__c> dispatchLocationMap = new Map<Integer, DispatchLocation__c>();
		List<DispatchLocation__c> dispatchLocations = [SELECT Name, SequenceNumber__c, Type__c, IsInternalCollection__c, IsBinCollection__c,
			Location__c, Location__r.StreetSegmentId__c, Location__r.CollectionPriority__c
			FROM DispatchLocation__c WHERE Dispatch__r.RoutingJobId__c = :routingResponse.jobId AND Location__r.IsLive__c = true];
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			dispatchLocationMap.put(Convert.toInteger(dispatchLocation.Name), dispatchLocation);
		}

		DispatchLocation__c dispatchLocation;
		for (RoutingResponse.ServiceLocation location : routingResponse.serviceLocations) {
			dispatchLocation = dispatchLocationMap.get(location.recordID);
			if (dispatchLocation == null) {continue;}	// Dead location
			dispatchLocation.SequenceNumberRaaS__c = dispatchLocation.SequenceNumber__c = location.sequence;
		}
		resequence(dispatchLocationMap.values());

		UPDATE dispatchLocationMap.values();
		updateJob(new DailyDispatch__c(RoutingStatus__c = 'Completed', RoutingSummary__c = JSON.serializePretty(routingResponse.routeSummary)));
	}

	protected override String key(sObject record) {
		DispatchLocation__c dispatchLocation = (DispatchLocation__c)record;
		return isCluster(dispatchLocation) ? dispatchLocation.Location__r.StreetSegmentId__c : dispatchLocation.Location__c;
	}

	private Boolean isCluster(DispatchLocation__c dispatchLocation) {
		return String.isNotBlank(dispatchLocation.Location__r.StreetSegmentId__c) &&
			dispatchLocation.Location__r.CollectionPriority__c == 'Normal' && dispatchLocation.Type__c == 'Normal' &&
			!dispatchLocation.IsInternalCollection__c && !dispatchLocation.IsBinCollection__c;
	}

	private void updateJob(DailyDispatch__c dispatch) {
		dispatch.RoutingJobId__c = jobId;
		dispatch.RoutingPollCount__c = pollCount;
		UPSERT dispatch RoutingJobId__c;
	}
}