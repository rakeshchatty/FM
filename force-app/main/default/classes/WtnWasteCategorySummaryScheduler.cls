public without sharing class WtnWasteCategorySummaryScheduler implements Schedulable {

    public void execute(SchedulableContext sc) {
		System.enqueueJob(new WtnWasteCategorySummaryQueuable());
	}
}