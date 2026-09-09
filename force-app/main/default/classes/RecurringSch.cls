global class RecurringSch implements Schedulable {
	global void execute(SchedulableContext sc) {
		RecurringBatch b = new RecurringBatch();
		database.executebatch(b, 10);
	}
}