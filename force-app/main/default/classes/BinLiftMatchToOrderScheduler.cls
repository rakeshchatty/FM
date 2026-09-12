public without sharing class BinLiftMatchToOrderScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new BinLiftMatchToOrderBatch(), 100);
	}
}