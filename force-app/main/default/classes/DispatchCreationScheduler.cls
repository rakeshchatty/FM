public class DispatchCreationScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new DispatchCreationBatch(), 1);
	}
}