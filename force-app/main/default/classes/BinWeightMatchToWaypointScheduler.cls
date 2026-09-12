public class BinWeightMatchToWaypointScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new BinWeightMatchToWaypointBatch(), 100);
	}
}