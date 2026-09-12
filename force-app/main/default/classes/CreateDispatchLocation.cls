public without sharing class CreateDispatchLocation {

	private static final CollectionServiceTimeSetting__c SERVICE_TIME = CollectionServiceTimeSetting__c.getOrgDefaults();
	private static final String KEY_FORMAT = '{0}-{1}';

	public static Map<String, DispatchLocation__c> create(Round__c round, Id dispatchId) {
		Map<Id, Wrapper> locationMap = new Map<Id, Wrapper>();
		for (Schedule__c schedule : round.Collections__r) {
			if (locationMap.containsKey(schedule.Location__c)) {
				locationMap.get(schedule.Location__c).collate(schedule);
			} else {
				locationMap.put(schedule.Location__c, new Wrapper(schedule, dispatchId));
			}
		}

		Map<String, DispatchLocation__c> dispatchLocationMap = new Map<String, DispatchLocation__c>();
		for (Wrapper wrapper : locationMap.values()) {
			dispatchLocationMap.put(wrapper.key(), wrapper.convert());
		}
		return dispatchLocationMap;
	}

	public static Map<String, DispatchLocation__c> create(List<Collection_Waypoints__c> newWaypoints) {
		// Fetch additional related fields
		List<Collection_Waypoints__c> waypoints = [SELECT Daily_Dispatch__c, Location__c, Location__r.Parent.Account_Manager__c, Type__c,
			Collection_Schedule__r.Is_Internal_Collection__c, Collection_Schedule__r.Is_bin_collection__c, Collection_Schedule__r.Collection_Quantity__c,
			Collection_Schedule__r.Time__c, Collection_Schedule__r.EarliestArrival__c, Collection_Schedule__r.LatestArrival__c
			FROM Collection_Waypoints__c WHERE Id IN :newWaypoints];

		Set<Id> dispatchIds = new Set<Id>();
		Set<Id> locationIds = new Set<Id>();

		Map<String, List<Collection_Waypoints__c>> waypointMap = new Map<String, List<Collection_Waypoints__c>>();
		for (Collection_Waypoints__c waypoint : waypoints) {
			dispatchIds.add(waypoint.Daily_Dispatch__c);
			locationIds.add(waypoint.Location__c);
			String key = key(waypoint);
			if (waypointMap.containsKey(key)) {
				waypointMap.get(key).add(waypoint);
			} else {
				waypointMap.put(key, new List<Collection_Waypoints__c>{waypoint});
			}
		}

		Map<String, Wrapper> locationMap = new Map<String, Wrapper>();
		List<DispatchLocation__c> dispatchLocations = [SELECT Dispatch__c, Location__c, Location__r.Parent.Account_Manager__c, IsInternalCollection__c,
			IsBinCollection__c, BinCount__c, Time__c, EarliestArrival__c, LatestArrival__c, Type__c, Status__c
			FROM DispatchLocation__c WHERE Dispatch__c IN :dispatchIds AND Location__c IN :locationIds];
		for (DispatchLocation__c dispatchLocation : dispatchLocations) {
			String key = key(dispatchLocation);
			if (waypointMap.containsKey(key)) {
				locationMap.put(key, new Wrapper(dispatchLocation));
			}
		}

		for (String key : waypointMap.keySet()) {
			for (Collection_Waypoints__c waypoint : waypointMap.get(key)) {
				if (locationMap.containsKey(key)) {
					locationMap.get(key).collate(waypoint);
				} else {
					locationMap.put(key, new Wrapper(waypoint));
				}
			}
		}

		Map<String, DispatchLocation__c> dispatchLocationMap = new Map<String, DispatchLocation__c>();
		for (String key : locationMap.keySet()) {
			dispatchLocationMap.put(key, locationMap.get(key).convert());
		}
		return dispatchLocationMap;
	}

	public static String key(Collection_Waypoints__c waypoint) {
		return key(waypoint.Daily_Dispatch__c, waypoint.Location__c);
	}

	public static String key(DispatchLocation__c dispatchLocation) {
		return key(dispatchLocation.Dispatch__c, dispatchLocation.Location__c);
	}

	public static String key(Id dispatchId, Id locationId) {
		return String.format(KEY_FORMAT, new Object[]{dispatchId, locationId});
	}

	private class Wrapper {
		private Id dispatchLocationId;
		private Id dispatchId;
		private Id locationId;
		private Boolean isManaged = false;
		private Boolean isInternal = false;
		private Boolean isBin = false;
		private Decimal binCount = 0;
		private Time collectionTime;
		private Time earliestArrival;
		private Time latestArrival;
		private String type = 'Normal';
		private String status = 'Pending';

		private Wrapper(Schedule__c schedule, Id dispatchId) {
			this.dispatchId = dispatchId;
			locationId = schedule.Location__c;
			isManaged = schedule.Location__r.Parent.Account_Manager__c != null;
			collate(schedule);
		}

		private Wrapper(DispatchLocation__c dispatchLocation) {
			dispatchLocationId = dispatchLocation.Id;
			dispatchId = dispatchLocation.Dispatch__c;
			locationId = dispatchLocation.Location__c;
			isManaged = dispatchLocation.Location__r.Parent.Account_Manager__c != null;
			isInternal = dispatchLocation.IsInternalCollection__c;
			isBin = dispatchLocation.IsBinCollection__c;
			binCount = dispatchLocation.BinCount__c;
			collectionTime = dispatchLocation.Time__c;
			earliestArrival = dispatchLocation.EarliestArrival__c;
			latestArrival = dispatchLocation.LatestArrival__c;
			type = dispatchLocation.Type__c;
			status = dispatchLocation.Status__c;
		}

		private Wrapper(Collection_Waypoints__c waypoint) {
			dispatchId = waypoint.Daily_Dispatch__c;
			locationId = waypoint.Location__c;
			isManaged = waypoint.Location__r.Parent.Account_Manager__c != null;
			collate(waypoint);
		}

		private String key() {
			return key(dispatchId, locationId);
		}

		private void collate(Collection_Waypoints__c waypoint) {
			collate(waypoint.Collection_Schedule__r);
			type = (type == 'Missed' || waypoint.Type__c == 'Missed') ? 'Missed' : (waypoint.Type__c == 'Extra') ? 'Extra' : 'Normal';
			status = (type == 'Missed' || type == 'Extra') ? 'Pending' : status;
		}

		private void collate(Schedule__c schedule) {
			if (schedule == null) {
				return;
			}

			isInternal |= schedule.Is_Internal_Collection__c;
			isBin |= schedule.Is_bin_collection__c;
			binCount += schedule.Is_bin_collection__c ? schedule.Collection_Quantity__c : 0;
			Time scheduleTime = Convert.toTime(schedule.Time__c);
			collectionTime = collectionTime == null ? scheduleTime : (scheduleTime < collectionTime ? scheduleTime : collectionTime);
			earliestArrival = earliestArrival == null ? schedule.EarliestArrival__c : (schedule.EarliestArrival__c < earliestArrival ? schedule.EarliestArrival__c : earliestArrival);
			latestArrival = latestArrival == null ? schedule.LatestArrival__c : (schedule.LatestArrival__c > latestArrival ? schedule.LatestArrival__c : latestArrival);
		}

		private DispatchLocation__c convert() {
			return new DispatchLocation__c(Id = dispatchLocationId, Dispatch__c = dispatchId, Location__c = locationId, IsInternalCollection__c = isInternal, IsBinCollection__c = isBin, BinCount__c = binCount,
				ServiceTime__c = isInternal ? SERVICE_TIME.Internal__c : (binCount > 0 ? SERVICE_TIME.TimePerBinStop__c + (binCount * SERVICE_TIME.TimePerBin__c) : (isManaged ? SERVICE_TIME.BagsBigAccount__c : SERVICE_TIME.BagsSmallAccount__c)),
				Time__c = collectionTime, EarliestArrival__c = earliestArrival, LatestArrival__c = latestArrival, Type__c = type, Status__c = status);
		}
	}
}