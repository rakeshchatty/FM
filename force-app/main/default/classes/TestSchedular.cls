public class TestSchedular implements Schedulable {

	private DateTime dueDate;

	public TestSchedular() {
		this.dueDate = System.now();
        System.debug('Constructor - dueDate : ' + dueDate);
	}

	public TestSchedular(DateTime someDateTime) {
		this.dueDate = someDateTime;
	}

	public void execute(SchedulableContext sc) {
		System.debug('execute - dueDate :: ' + dueDate);
	}
}