public without sharing class ClusterSequenceBatch implements Database.Batchable<Id> {
	List<Id> dispatchIds = null;

	public ClusterSequenceBatch(List<Id> dispatchIds) {
		this.dispatchIds = dispatchIds;
	}

	public ClusterSequenceBatch(Set<Id> dispatchIds) {
		this(new List<Id>(dispatchIds));
	}

	public Iterable<Id> start(Database.BatchableContext batchContext) {
		return dispatchIds;
	}

	public void execute(Database.BatchableContext batchContext, List<Id> dispatchIds) {
		List<DispatchLocation__c> dispatchLocations = [SELECT Name, SequenceNumber__c, Type__c, IsInternalCollection__c, IsBinCollection__c,
			Location__c, Location__r.StreetSegmentId__c, Location__r.CollectionPriority__c
			FROM DispatchLocation__c WHERE Dispatch__c = :dispatchIds[0] AND Location__r.IsLive__c = true];

		Integer incrementalSequence = 0;
		Integer assignedSequence;
		Map<String, Integer> keyToSequence = new Map<String, Integer>();
		List<DispatchLocation__c> dispatchLocationsToUpdate = new List<DispatchLocation__c>();
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			if (!isCluster(dispatchLocation)) {
				assignedSequence = ++incrementalSequence;
			} else {
				assignedSequence = keyToSequence.get(dispatchLocation.Location__r.StreetSegmentId__c);
				if (assignedSequence == null) {
					assignedSequence = ++incrementalSequence;
					keyToSequence.put(dispatchLocation.Location__r.StreetSegmentId__c, assignedSequence);
				}
			}
			dispatchLocation.SequenceNumber__c = assignedSequence;
			dispatchLocationsToUpdate.add(dispatchLocation);
		}

		if (!dispatchLocationsToUpdate.isEmpty()) {
			UPDATE dispatchLocationsToUpdate;
		}
	}

	public void finish(Database.BatchableContext batchContext) {}

	private Boolean isCluster(DispatchLocation__c dispatchLocation) {
		return String.isNotBlank(dispatchLocation.Location__r.StreetSegmentId__c) &&
			dispatchLocation.Location__r.CollectionPriority__c == 'Normal' && dispatchLocation.Type__c == 'Normal' &&
			!dispatchLocation.IsInternalCollection__c && !dispatchLocation.IsBinCollection__c;
	}
}