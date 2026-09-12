public without sharing class WtnWasteCategoryTriggerHandler {

	public void handleTrigger(List<WTN_Waste_Category__c> newList, Map<Id, WTN_Waste_Category__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				applyOnSchedules(newList);
			}
		}
	}

	private void applyOnSchedules(List<WTN_Waste_Category__c> wtnWasteCategories) {
		// Filter by Season Ticket WTN records
		List<WTN_Waste_Category__c> seasonTicketWasteCategories = [SELECT WTN__r.Account__c, WTN__r.Contractor__c, Product__c FROM WTN_Waste_Category__c
			WHERE ID IN :wtnWasteCategories AND WTN__r.Name LIKE 'Season Ticket WTN%'];
		if (!seasonTicketWasteCategories.isEmpty()) {
			WtnWasteCategoryOnSchedule.apply(seasonTicketWasteCategories);
		}
	}
}