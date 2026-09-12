public without sharing class CreateWaypointFromMissedCollection {

	@InvocableMethod(label='Create Additional Waypoint From Missed Collection')
	public static void create(List<Id> missedCollectionIds) {
		CreateWaypoint.create(fetch(missedCollectionIds));
	}

	private static List<Missed_Collection__c> fetch(List<Id> missedCollectionIds) {
		return [SELECT Case__c, Case__r.Type, Case__r.AccountId, DispatchAllocated__c, DispatchAllocated__r.RoundId__c,
			Collection_Schedule__c, Collection_Schedule__r.Name, Collection_Schedule__r.Is_bin_collection__c,
			Collection_Schedule__r.Collection_Quantity__c, Collection_Schedule__r.Supplier__c, Collection_Schedule__r.Supplier_Product__c
		FROM Missed_Collection__c WHERE Id IN :missedCollectionIds];
	}
}