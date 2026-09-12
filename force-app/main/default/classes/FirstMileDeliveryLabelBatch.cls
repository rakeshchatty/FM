public without sharing class FirstMileDeliveryLabelBatch implements Database.Batchable<DeliveryPackage__c> {

	private List<DeliveryPackage__c> packages = new List<DeliveryPackage__c>();

	public FirstMileDeliveryLabelBatch(List<DeliveryPackage__c> packages) {
		this.packages = packages;
	}

	public Iterable<DeliveryPackage__c> start(Database.BatchableContext batchContext) {
		return packages;
	}

	public void execute(Database.BatchableContext BC, List<DeliveryPackage__c> scope) {
		List<DeliveryPackage__c> packages = new List<DeliveryPackage__c>();
		List<Attachment> attachments = new List<Attachment>();
		for (DeliveryPackage__c pkg : scope) {
			Attachment attachment = new Attachment();
			attachment.ParentId = pkg.Id;
			attachment.Name = pkg.Carrier__c + ' Label - ' + pkg.Name + '.pdf';
			attachment.Body = createLabelPdf(pkg);
			attachments.add(attachment);
			packages.add(new DeliveryPackage__c(Id = pkg.Id, Status__c = DeliveryPackage.STATUS_LABELLED, Message__c = ''));
		}
		INSERT attachments;
		UPDATE packages;
	}

	private Blob createLabelPdf(DeliveryPackage__c pkg) {
		PageReference pdf = Page.DeliveryPackageLabel;
		pdf.getParameters().put('Id', pkg.Id);
		return Test.isRunningTest() ? Blob.valueOf('test') : pdf.getContentAsPdf();
	}

	public void finish(Database.BatchableContext BC) {}
}