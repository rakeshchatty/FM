public without sharing class RoyalMailTrackingEvent {

	private RoyalMailSetting__c setting = RoyalMailSetting__c.getOrgDefaults();
	private String deliveredStatus = setting.StatusDelivered__c;
	private String finalStatus = deliveredStatus + ',' + setting.StatusReturnedToSender__c + ',' + setting.StatusCancelled__c;

	public void process(List<DeliveryPackageTrackingEvent__c> newList) {
		Map<String, List<TrackingEventWrapper>> trackingEventMap = groupEventsByTrackingId(newList);
		Map<String, DeliveryPackageItem__c> itemsToUpdate = new Map<String, DeliveryPackageItem__c>();
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
			itemsToUpdate.put(trackingId, new DeliveryPackageItem__c(TrackingId__c = trackingId, Event__c = event.Code__c, DeliveredDate__c = deliveredStatus.contains(event.Code__c) ? event.DateTime__c : null));
		}
		UPDATE filterInProgressPackages(itemsToUpdate);
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

	private List<DeliveryPackageItem__c> filterInProgressPackages(Map<String, DeliveryPackageItem__c> itemsByTrackingId) {
		List<DeliveryPackageItem__c> itemsInProgress = [SELECT TrackingId__c FROM DeliveryPackageItem__c WHERE TrackingId__c IN :itemsByTrackingId.keySet() AND IsFinalStatus__c = false AND IsDraftStatus__c = false];

		List<DeliveryPackageItem__c> filteredItems = new List<DeliveryPackageItem__c>();
		for (DeliveryPackageItem__c itemInProgress : itemsInProgress) {
			DeliveryPackageItem__c item = itemsByTrackingId.get(itemInProgress.TrackingId__c);
			item.Id = itemInProgress.Id;
			filteredItems.add(item);
		}
		return filteredItems;
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