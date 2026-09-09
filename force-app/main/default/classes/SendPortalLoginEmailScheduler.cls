public class SendPortalLoginEmailScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new SendPortalLoginEmailBatch(), 100);
	}
}