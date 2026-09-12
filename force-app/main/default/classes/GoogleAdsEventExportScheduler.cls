public without sharing class GoogleAdsEventExportScheduler implements Schedulable {

	public void execute(SchedulableContext context) {
		new GoogleAdsEventExporter().export();
	}
}