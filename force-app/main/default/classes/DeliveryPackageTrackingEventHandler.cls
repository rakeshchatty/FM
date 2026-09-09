public without sharing class DeliveryPackageTrackingEventHandler {

	private ParcelforceSetting__c setting = ParcelforceSetting__c.getOrgDefaults();
	private String deliveredStatus = setting.StatusDelivered__c;
	private String finalStatus = deliveredStatus + ',' + setting.StatusRedelivery__c + ',' + setting.StatusCancelled__c;

	public void handleTrigger(List<DeliveryPackageTrackingEvent__c> newList, Map<Id, DeliveryPackageTrackingEvent__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				processEvents(newList);
			}
		}
	}

	private void processEvents(List<DeliveryPackageTrackingEvent__c> newList) {
		Map<String, List<TrackingEventWrapper>> trackingEventMap = groupEventsByTrackingId(newList);
		Map<String, DeliveryPackage__c> packagesToUpdate = new Map<String, DeliveryPackage__c>();
		for (String trackingId : trackingEventMap.keySet()) {
			List<TrackingEventWrapper> wrapperEvents = trackingEventMap.get(trackingId);
			wrapperEvents.sort();
			DeliveryPackageTrackingEvent__c event = wrapperEvents[0].event;
			if (wrapperEvents.size() > 1) {
				for (TrackingEventWrapper wrapper : wrapperEvents) {
					if (finalStatus.contains(wrapper.event.Code__c)) {
						event = wrapper.event;
						break;
					}
				}
			}
			packagesToUpdate.put(trackingId, new DeliveryPackage__c(TrackingId__c = trackingId, ParcelforceEvent__c = event.Code__c, DeliveredDate__c = deliveredStatus.contains(event.Code__c) ? event.DateTime__c : null));
		}
		UPDATE filterInProgressPackages(packagesToUpdate);
	}

	private Map<String, List<TrackingEventWrapper>> groupEventsByTrackingId(List<DeliveryPackageTrackingEvent__c> newList) {
		Map<String, List<TrackingEventWrapper>> trackingEventMap = new Map<String, List<TrackingEventWrapper>>();
		for (DeliveryPackageTrackingEvent__c trackingEvent : newList) {
			if (!trackingEventMap.containsKey(trackingEvent.Name)) {
				trackingEventMap.put(trackingEvent.Name, new List<TrackingEventWrapper>{new TrackingEventWrapper(trackingEvent)});
				continue;
			}
			trackingEventMap.get(trackingEvent.Name).add(new TrackingEventWrapper(trackingEvent));
		}
		return trackingEventMap;
	}

	private List<DeliveryPackage__c> filterInProgressPackages(Map<String, DeliveryPackage__c> packagesByTrackingId) {
		List<DeliveryPackage__c> packages = [SELECT TrackingId__c FROM DeliveryPackage__c WHERE TrackingId__c IN :packagesByTrackingId.keySet() AND IsFinalStatus__c = false AND IsDraftStatus__c = false];

		List<DeliveryPackage__c> inProgressPackages = new List<DeliveryPackage__c>();
		for (DeliveryPackage__c pkg : packages) {
			DeliveryPackage__c deliveryPackage = packagesByTrackingId.get(pkg.TrackingId__c);
			deliveryPackage.Id = pkg.Id;
			inProgressPackages.add(deliveryPackage);
		}
		return inProgressPackages;
	}

	private class TrackingEventWrapper implements Comparable {
		private DeliveryPackageTrackingEvent__c event;

		private TrackingEventWrapper(DeliveryPackageTrackingEvent__c event) {
			this.event = event;
		}

		public Integer compareTo(Object compareTo) {
			TrackingEventWrapper compareToEvent = (TrackingEventWrapper)compareTo;
			if (event.DateTime__c == compareToEvent.event.DateTime__c) return 0;
			if (event.DateTime__c > compareToEvent.event.DateTime__c) return -1;
			return 1;
		}
	}
}