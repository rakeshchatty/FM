public without sharing class DeliveryPackageLabelBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

	private Set<Id> packageIds = new Set<Id>();

	public DeliveryPackageLabelBatch(Set<Id> packageIds) {
		this.packageIds = packageIds;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT TrackingId__c FROM DeliveryPackage__c WHERE Id IN :packageIds AND Status__c = :DeliveryPackage.STATUS_ADVISED]);
	}

	public void execute(Database.BatchableContext BC, List<DeliveryPackage__c> scope) {
		List<Attachment> attachments = new List<Attachment>();
		for (DeliveryPackage__c pkg : scope) {
			pkg.Message__c = '';
			ParcelforceSoap.PrintLabelReply response = new ParcelforceSoap.ShipServicePort().printLabel(pkg.TrackingId__c);
			if (response.Label != null) {
				Attachment attachment = new Attachment();
				attachment.ParentId = pkg.Id;
				attachment.Name = 'Parcelforce Label - ' + pkg.TrackingId__c + '.pdf';
				attachment.Body = EncodingUtil.base64Decode(response.Label.Data);
				attachments.add(attachment);
				pkg.Status__c = DeliveryPackage.STATUS_LABELLED;
			} else {
				pkg.Status__c = DeliveryPackage.STATUS_ERROR;
				ParcelforceSoap.Alerts alerts = response.Alerts;
				for (ParcelforceSoap.Alert alert : alerts.Alert) {
					pkg.Message__c += alert.Message + ('\n');
				}
			}
		}
		INSERT attachments;
		UPDATE scope;
	}

	public void finish(Database.BatchableContext BC) {}
}