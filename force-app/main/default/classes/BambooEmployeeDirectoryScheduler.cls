public without sharing class BambooEmployeeDirectoryScheduler implements Schedulable {

	public void execute(SchedulableContext context) {
		System.enqueueJob(new BambooEmployeeDirectoryQueueable());
	}
}