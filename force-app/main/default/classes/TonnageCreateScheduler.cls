public without sharing class TonnageCreateScheduler implements Schedulable {

	public void execute(SchedulableContext SC) {
		Database.executeBatch(new TonnageCreateBatch(), 200);
	}
}