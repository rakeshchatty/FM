public without sharing class SeasonTicketWtnRenewalScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new SeasonTicketWtnRenewalBatch(), 1);
	}
}