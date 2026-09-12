public without sharing class CreateWaypointFromCase {

	@InvocableMethod(label='Create Additional Waypoint From Case')
	public static void create(List<Id> caseIds) {
		CreateWaypoint.create(fetch(caseIds));
	}

	private static List<Case> fetch(List<Id> caseIds) {
		return [SELECT Type, AccountId, Supplier__c, SupplierProduct__c, Quantity__c, Round_Dispatched__c, Round_Dispatched__r.RoundId__c, ManualPrice__c, SupplierUnitPrice__c FROM Case WHERE Id IN :caseIds];
	}
}