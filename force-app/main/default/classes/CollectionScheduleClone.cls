public without sharing class CollectionScheduleClone {

	@InvocableMethod(Label='Clone Collection Schedule')
	public static List<Schedule__c> clone(List<Id> schedules) {
		List<Schedule__c> clonedSchedules = new List<Schedule__c>();
		List<Schedule__c> selectedSchedules = [SELECT Location__c, Supplier__c, Supplier_Product__c, Days__c, Time__c, Collection_Quantity__c,
			Discount_Type__c, Enqix_Price__c, List_Price__c, Sale_Price__c, Location_Collection_Notes__c, Price_Book__c, Product__c, Streams__c,
			Agreed_Length_of_Collection_Window__c, Collection_Day__c, Collection_Note__c, Future_GW__c, Future_DMR__c, EarliestArrival__c,
			LatestArrival__c, WeekFrequency__c, Week_Off__c, Start_Date__c FROM Schedule__c WHERE Id IN :schedules];

		for (Schedule__c schedule : selectedSchedules) {
			Schedule__c clonedSchedule = schedule.clone(false, true, true, false);
			clonedSchedule.Discount_Type__c = schedule.Discount_Type__c;
			clonedSchedule.Start_Date__c = schedule.Start_Date__c;
			clonedSchedules.add(clonedSchedule);
		}

		return clonedSchedules;
	}
}