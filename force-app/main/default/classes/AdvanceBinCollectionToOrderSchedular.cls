public without sharing class AdvanceBinCollectionToOrderSchedular implements Schedulable {
	
	Boolean isDelta;

	public AdvanceBinCollectionToOrderSchedular(Boolean isDelta) {
		this.isDelta = isDelta;
	}

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new AdvanceBinCollectionToOrderBatch(isDelta));
	}
}