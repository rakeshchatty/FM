public without sharing class InfinityFileExportScheduler implements Schedulable {

	public void execute(SchedulableContext context) {
		new InfinityFileExporter().export();
	}
}