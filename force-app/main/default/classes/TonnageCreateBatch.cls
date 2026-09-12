public without sharing class TonnageCreateBatch implements Database.Batchable<SObject> {

	private final String DEFAULT_DISPATCH = TonnageSettings__c.getOrgDefaults().DefaultDispatch__c;

	public Database.QueryLocator start(Database.BatchableContext context) {
		return Database.getQueryLocator([SELECT TypeOfWaste__c, Net__c, TimeOfTip__c, DateOfTip__c, RoundNumber__c FROM WeightronEvent__c WHERE Status__c = 'New']);
	}

	public void execute(Database.BatchableContext context, List<WeightronEvent__c> scope) {
		createTonnage(scope);
	}

	private void createTonnage(List<WeightronEvent__c> events) {
		Map<String, DailyDispatch__c> dispatchMap = getDispatches(events);

		List<WeightronEvent__c> eventsToUpdate = new List<WeightronEvent__c>();
		WeightronEvent__c eventToUpdate;
		List<Tonnage__c> tonnages = new List<Tonnage__c>();
		Tonnage__c tonnage;
		DailyDispatch__c dispatch;
		Date previousDate;

		for (WeightronEvent__c event : events) {
			eventToUpdate = new WeightronEvent__c(Id = event.Id);
			tonnage = new Tonnage__c(Site_of_Tip__c = 'Weighbridge', Type_of_Waste__c = event.TypeOfWaste__c, Weight_kg__c = event.Net__c, Time_of_Tip__c = event.TimeOfTip__c);
			dispatch = dispatchMap.get(key(event));
			previousDate = event.DateOfTip__c.addDays(-1);
			if (dispatch == null) {	// Current day's dispatched not yet created. E.g. Event of PM round @ 02:05 AM
				// Try previous date
				dispatch = dispatchMap.get(key(event.RoundNumber__c, previousDate));
				if (dispatch == null || dispatch.RoundId__r.Round_Type__c != 'PM') {
					setDispatch(tonnage, eventToUpdate, DEFAULT_DISPATCH, event.DateOfTip__c, 'Not Matched');
				} else {
					setDispatch(tonnage, eventToUpdate, dispatch.Id, previousDate, 'Matched');				// PM previous day when current day record not created yet
				}
			} else {
				if (dispatch.RoundId__r.Round_Type__c == 'PM') {
					if (event.TimeOfTip__c.hour() >= 0 && event.TimeOfTip__c.hour() <= 16) {				// PM round but time is before PM start, so find previous day dispatch
						// Get previous date
						dispatch = dispatchMap.get(key(event.RoundNumber__c, previousDate));
						if (dispatch == null) {
							setDispatch(tonnage, eventToUpdate, DEFAULT_DISPATCH, event.DateOfTip__c, 'Not Matched');
						} else {
							setDispatch(tonnage, eventToUpdate, dispatch.Id, previousDate, 'Matched');		// PM previous day
						}
					} else {
						setDispatch(tonnage, eventToUpdate, dispatch.Id, event.DateOfTip__c, 'Matched');	// PM same day
					}
				} else {
					setDispatch(tonnage, eventToUpdate, dispatch.Id, event.DateOfTip__c, 'Matched');		// AM
				}
			}

			tonnages.add(tonnage);
			eventsToUpdate.add(eventToUpdate);
		}

		Database.SaveResult[] results = Database.insert(tonnages, false);
		LogRegister.createLogsUpsert(results, tonnages, 'Create Tonnages from Weightron Events', 'Insert', 'Tonnage__c', 'DailyDispatch__c');

		results = Database.update(eventsToUpdate, false);
		LogRegister.createLogsUpsert(results, eventsToUpdate, 'Status update on Weightron Events', 'Update', 'WeightronEvent__c', null);
	}

	private Map<String, DailyDispatch__c> getDispatches(List<WeightronEvent__c> events) {
		Set<Decimal> roundNumbers = new Set<Decimal>();
		Set<Date> dispatchDates = new Set<Date>();
		for (WeightronEvent__c event : events) {
			roundNumbers.add(event.RoundNumber__c);
			dispatchDates.add(event.DateOfTip__c);
			dispatchDates.add(event.DateOfTip__c.addDays(-1));
		}

		Map<String, DailyDispatch__c> dispatchMap = new Map<String, DailyDispatch__c>();

		List<DailyDispatch__c> dispatches = [SELECT RoundId__r.RoundNo__c, RoundId__r.Round_Type__c, Dispatch_Date__c FROM DailyDispatch__c
			WHERE RoundId__r.RoundNo__c IN :roundNumbers AND Dispatch_Date__c IN :dispatchDates];
		for (DailyDispatch__c dispatch : dispatches) {
			dispatchMap.put(key(dispatch), dispatch);
		}

		return dispatchMap;
	}

	private void setDispatch(Tonnage__c tonnage, WeightronEvent__c event, Id dispatchId, Date dispatchDate, String status) {
		tonnage.DailyDispatch__c = dispatchId;
		tonnage.Date_of_Round__c = dispatchDate;
		event.Status__c = status;
	}

	private static String key(DailyDispatch__c dispatch) {
		return key(dispatch.RoundId__r.RoundNo__c, dispatch.Dispatch_Date__c);
	}

	private static String key(WeightronEvent__c event) {
		return key(event.RoundNumber__c, event.DateOfTip__c);
	}

	private static String key(Decimal roundNumber, Date dispatchDate) {
		return String.format('{0}-{1}', new Object[]{roundNumber, dispatchDate});
	}

	public void finish(Database.BatchableContext context) {}
}