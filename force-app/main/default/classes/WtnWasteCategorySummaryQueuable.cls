public without sharing class WtnWasteCategorySummaryQueuable implements Queueable {

	private final Boolean ALL_RECORDS;
	private List<String> wtnIds;
	private List<Schedule__c> schedules;

	public WtnWasteCategorySummaryQueuable() {
		this(false);
	}

	public WtnWasteCategorySummaryQueuable(Boolean allRecords) {
		ALL_RECORDS = allRecords;
	}

	public WtnWasteCategorySummaryQueuable(List<String> wtnIds) {
		this();
		this.wtnIds = wtnIds;
	}

	public WtnWasteCategorySummaryQueuable(List<Schedule__c> schedules) {
		this();
		this.schedules = schedules;
	}

	public void execute(QueueableContext context) {
		if (wtnIds != null && !wtnIds.isEmpty()) {
			Database.executebatch(new WtnWasteCategorySummaryBatch(wtnIds), 10);
		} else if (schedules != null && !schedules.isEmpty()) {
			Database.executebatch(new WtnWasteCategorySummaryBatch(schedules), 10);
		} else {
			Database.executebatch(new WtnWasteCategorySummaryBatch(ALL_RECORDS), 10);
		}
	}
}