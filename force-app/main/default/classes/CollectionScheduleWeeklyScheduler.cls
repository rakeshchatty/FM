public without sharing class CollectionScheduleWeeklyScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new CollectionScheduleWeeklyBatch(), 500);
	}
}