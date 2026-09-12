public without sharing class BinRentalChargeSchedular implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executeBatch(new BinRentalChargeBatch(), 10);
	}
}