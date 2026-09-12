public class InvoiceClosureScheduler implements Schedulable {

	public void execute(SchedulableContext sc) {
		Database.executebatch(new InvoiceClosureBatch(), 15);
	}
}