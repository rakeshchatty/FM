global class wasteTransferNoteDueSch implements Schedulable{
	global void execute(SchedulableContext sc) {
		wasteTransferNoteDueBatch b = new wasteTransferNoteDueBatch();
		database.executebatch(b, 200);
	}
}