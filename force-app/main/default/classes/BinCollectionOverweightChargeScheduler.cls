public class BinCollectionOverweightChargeScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new BinCollectionOverweightChargeBatch(), 50);
	}
}