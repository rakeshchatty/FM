public without sharing class DeliveryPackageCancellationBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

	private static final String SUCCESS_STATUS = 'CANCELLED';

	private Set<Id> packageIds = new Set<Id>();

	public DeliveryPackageCancellationBatch(Set<Id> packageIds) {
		this.packageIds = packageIds;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT TrackingId__c FROM DeliveryPackage__c WHERE Id IN :packageIds AND Status__c = :DeliveryPackage.STATUS_CANCEL_REQUEST]);
	}

	public void execute(Database.BatchableContext BC, List<DeliveryPackage__c> scope) {
		for (DeliveryPackage__c pkg : scope) {
			pkg.Status__c = DeliveryPackage.STATUS_CANCELLED;
			pkg.Message__c = '';
			ParcelforceSoap.CancelShipmentReply response = new ParcelforceSoap.ShipServicePort().cancelShipment(pkg.TrackingId__c);
			if (response.CompletedCancel == null || response.CompletedCancel.CompletedCancelInfo.Status != SUCCESS_STATUS) {
				ParcelforceSoap.Alerts alerts = response.Alerts;
				if (alerts == null) {
					pkg.Message__c = JSON.serializePretty(response);
					continue;
				}
				for (ParcelforceSoap.Alert alert : alerts.Alert) {
					pkg.Message__c += alert.Message + ('\n');
				}
			}
		}
		UPDATE scope;
	}

	public void finish(Database.BatchableContext BC) {}
}