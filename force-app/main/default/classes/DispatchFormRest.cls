@RestResource(urlMapping='/DispatchForm/*')
global without sharing class DispatchFormRest {

	@HttpGet
	global static void get() {
		String requestURI = RestContext.request.requestURI;
		String dispatchId = requestURI.substring(requestURI.lastIndexOf('/') + 1);

		DailyDispatch__c dispatch = [SELECT Status__c, RoundId__c, WasKeyFolderTaken__c, CreatedDate,
			RoundId__r.Tip_1__c, RoundId__r.Tip_2__c, RoundId__r.Vehicle_Type__c, RoundId__r.Round_Notes__c
			FROM DailyDispatch__c WHERE Id = :dispatchId];
		List<Vehicle__c> vehicles = [SELECT Name FROM Vehicle__c WHERE Active__c = true ORDER BY Name];

		Response dipatchResponse = new Response(dispatch, vehicles);
		RestResponse response = RestContext.response;
		response.addHeader('Content-Type', 'application/json');
		response.responseBody = Blob.valueOf(JSON.serialize(dipatchResponse));
	}

	private static List<Account> getMissedLocations(DailyDispatch__c dispatch) {
		Id previousDispatchId;
		try {
			previousDispatchId = [SELECT Id FROM DailyDispatch__c WHERE RoundId__c = :dispatch.RoundId__c AND Id != :dispatch.Id AND CreatedDate < :dispatch.CreatedDate ORDER BY CreatedDate DESC LIMIT 1].Id;
		} catch (QueryException e) {
			return new List<Account>();
		}

		List<Missed_Collection__c> missedCollections = [SELECT Case__r.Location__c FROM Missed_Collection__c WHERE Daily_Dispatch__c = :previousDispatchId];
		Set<Id> locationIds = new Set<Id>();
		for (Missed_Collection__c missedCollection : missedCollections) {
			locationIds.add(missedCollection.Case__r.Location__c);
		}
		return [SELECT Name, BillingPostalCode, CollectionPriority__c FROM Account WHERE Id IN :locationIds];
	}

	private static List<Account> getReminderLocations(DailyDispatch__c dispatch) {
		return [SELECT CollectionPriority__c FROM Account WHERE Id IN
			(SELECT Location__c FROM DispatchLocation__c WHERE Dispatch__c = :dispatch.Id AND Location__r.CollectionPriority__c IN ('VIP', 'New'))];
	}

	private class Response {
		private transient DailyDispatch__c dispatch;

		private Boolean isStarted { get { return dispatch.Status__c != 'Created'; } }
		private Boolean isComplete { get { return dispatch.Status__c == 'Complete'; } }
		private Boolean wasKeyFolderTaken { get { return dispatch.WasKeyFolderTaken__c; } }
		private String tip1 { get { return dispatch.RoundId__r.Tip_1__c; } }
		private String tip2 { get { return dispatch.RoundId__r.Tip_2__c; } }
		private String vehicleType { get { return dispatch.RoundId__r.Vehicle_Type__c; } }
		private String notes { get { return dispatch.RoundId__r.Round_Notes__c; } }
		private List<Vehicle> vehicles = new List<Vehicle>();
		private List<Reminder> missedLocations = new List<Reminder>();
		private Integer countLocationsVip = 0;
		private Integer countLocationsNew = 0;

		private Response(DailyDispatch__c dispatch, List<Vehicle__c> vehicles) {
			this.dispatch = dispatch;

			for (Vehicle__c vehicle : vehicles) {
				this.vehicles.add(new Vehicle(vehicle));
			}

			for (Account location : getMissedLocations(dispatch)) {
				missedLocations.add(new Reminder(location));
			}
			for (Account location : getReminderLocations(dispatch)) {
				switch on location.CollectionPriority__c {
					when 'VIP' {
						countLocationsVip++;
					}
					when 'New' {
						countLocationsNew++;
					}
				}
			}
		}
	}

	private class Vehicle {
		private transient Vehicle__c vehicle;

		private Id id { get { return vehicle.Id; } }
		private String name { get { return vehicle.Name; } }

		private Vehicle(Vehicle__c vehicle) {
			this.vehicle = vehicle;
		}
	}

	private class Reminder {
		private transient Account location;

		private String locationName { get { return location.Name; } }
		private String postcode { get { return location.BillingPostalCode; } }
		private String type { get { return location.CollectionPriority__c; } }

		private Reminder(Account location) {
			this.location = location;
		}
	}
}