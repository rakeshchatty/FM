public with sharing class DailyDispatchTriggerHelper {

	static boolean alreadyRunUpdate = false;

	public static void beforeInsert(List < DailyDispatch__c > records) {
		Set < Id > vehicleIds = new Set < Id > ();
		for (DailyDispatch__c dd: records) {
			if (dd.Vehicle__c != null) vehicleIds.add(dd.Vehicle__c);
		}
		List < DailyDispatch__c > existingDDs = [select Id, Vehicle__c, RoundStartTime__c from DailyDispatch__c where RoundStartTime__c = null and Vehicle__c in: vehicleIds];
		if (existingDDs.size() > 0) {
			for (DailyDispatch__c dd: records) {
				for (DailyDispatch__c d: existingDDs) {
					if (dd.Vehicle__c == d.Vehicle__c && dd.RoundStartTime__c == null) dd.addError('An open Daily Dispatch with the selected vehicle already exists.');
				}
			}
		}
	}

	/* 
		-> Trigger : When a daily Dispatch is marked as complete, Status__c = 'Complete'
		create Edit Order and order products for every Collection Waypoint attached to that Daily Dispatch,
		For each Collection Waypoint attached to the Daily Dispatch (1 DD = x CWaypoints)
		Collection_Waypoints__c.Daily_Dispatch__c = DailyDispatch__c.Id
		
		with field isBinCollection = true;
		*/
    
    //Jira 1968 --> This after update will not be used anymore because it's causing the error "Unable to lock row" to frequently because of the amount of records being processed, this will now be done via batch class
}