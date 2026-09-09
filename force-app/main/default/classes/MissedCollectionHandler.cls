public with sharing class MissedCollectionHandler {

	@InvocableMethod(label='Process Missed Collections')
	public static void processMissedCollections(List<Id> caseIds) {
		createCollectionWaypoints(caseIds);
	}

	private static void createCollectionWaypoints(List<Id> caseIds) {
		List<Case> cases = fetchCase(caseIds);

		List<Collection_Waypoints__c> collectionWaypoints = new List<Collection_Waypoints__c>();

		for (Case missedCase : cases) {
			Collection_Waypoints__c collectionWaypoint = createCollectionWaypoint(missedCase);

			List<Missed_Collection__c> missedCollections = missedCase.Missed_Collections__r;
			if (missedCollections.isEmpty()) {
				collectionWaypoints.add(collectionWaypoint);
				continue;
			}

			for (Missed_Collection__c missedCollection : missedCollections) {
				Schedule__c schedule = missedCollection.Collection_Schedule__r;
				Collection_Waypoints__c cw = collectionWaypoint;
				cw.Name = schedule.Name;
				cw.Collection_Schedule__c = schedule.Id;
				cw.Is_bin_collection__c = schedule.Is_bin_collection__c;
				cw.Collection_Quantity__c = schedule.Collection_Quantity__c;
				cw.Supplier__c = schedule.Supplier__c;
				cw.Supplier_Product__c = schedule.Supplier_Product__c;
				collectionWaypoints.add(cw);
				collectionWaypoint = createCollectionWaypoint(missedCase);
			}
		}

		INSERT collectionWaypoints;
		INSERT createDispatchLocation(collectionWaypoints);
	}

	private static List<Case> fetchCase(List<Id> caseIds) {
		return [SELECT Type, AccountId, Round_Dispatched__c, Round_Dispatched__r.RoundId__c,
			(SELECT Collection_Schedule__c, Collection_Schedule__r.Name, Collection_Schedule__r.Is_bin_collection__c,
			Collection_Schedule__r.Collection_Quantity__c, Collection_Schedule__r.Supplier__c, Collection_Schedule__r.Supplier_Product__c
			FROM Missed_Collections__r WHERE Collection_Schedule__c != null)
		FROM Case WHERE Id IN :caseIds];
	}

	private static Collection_Waypoints__c createCollectionWaypoint(Case missedCase) {
		return new Collection_Waypoints__c(
			Name = missedCase.Type + ' - ' + missedCase.AccountId,
			Case__c = missedCase.Id,
			Location__c = missedCase.AccountId,
			Daily_Dispatch__c = missedCase.Round_Dispatched__c,
			Round__c = missedCase.Round_Dispatched__r.RoundId__c
		);
	}

	private static List<DispatchLocation__c> createDispatchLocation(List<Collection_Waypoints__c> collectionWaypoints) {
		Set<Id> dispatchIds = new Set<Id>();
		Set<Id> locationIds = new Set<Id>();
		Map<String, Collection_Waypoints__c> dispatchLocationMap = new Map<String, Collection_Waypoints__c>();
		for (Collection_Waypoints__c collectionWaypoint : collectionWaypoints) {
			dispatchIds.add(collectionWaypoint.Daily_Dispatch__c);
			locationIds.add(collectionWaypoint.Location__c);
			dispatchLocationMap.put(collectionWaypoint.Daily_Dispatch__c + '-' + collectionWaypoint.Location__c, collectionWaypoint);
		}

		for (DispatchLocation__c dispatchLocation : [SELECT Location__c, Dispatch__c FROM DispatchLocation__c WHERE Dispatch__c IN :dispatchIds AND Location__c IN :locationIds]) {
			dispatchLocationMap.remove(dispatchLocation.Dispatch__c + '-' + dispatchLocation.Location__c);
		}

		List<DispatchLocation__c> dispatchLocations = new List<DispatchLocation__c>();
		for (Collection_Waypoints__c collectionWaypoint : dispatchLocationMap.values()) {
			dispatchLocations.add(new DispatchLocation__c(Dispatch__c = collectionWaypoint.Daily_Dispatch__c, Location__c = collectionWaypoint.Location__c));
		}
		return dispatchLocations;
	}
}