public without sharing class AdvanceBinCollectionToOrderSchedular implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new AdvanceBinCollectionToOrderBatch(), 10);
	}
}