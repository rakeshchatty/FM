public class BinCollectionToOrderScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new BinCollectionToOrderBatch());
	}
}