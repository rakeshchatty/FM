public without sharing class SendGridEmailActivityScheduler implements Schedulable {

	public void execute(SchedulableContext context) {
		System.enqueueJob(new SendGridGetMessageQueueable());
	}
}