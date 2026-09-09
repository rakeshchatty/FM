public class InvoiceClosureScheduler implements Schedulable {

	private Date dueDate;

	public InvoiceClosureScheduler() {
		this.dueDate = System.today() - 1;
	}

	public InvoiceClosureScheduler(Date someDate) {
		this.dueDate = someDate;
	}

	public void execute(SchedulableContext sc) {
		Database.executebatch(new InvoiceClosureBatch(dueDate), 15);
	}
}