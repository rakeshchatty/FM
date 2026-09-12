public without sharing class RoyalMailDeliveryCancelBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {

	private Set<Id> packageIds = new Set<Id>();

	public RoyalMailDeliveryCancelBatch(Set<Id> packageIds) {
		this.packageIds = packageIds;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT TrackingIds__c FROM DeliveryPackage__c WHERE Id IN :packageIds AND Status__c = :DeliveryPackage.STATUS_CANCEL_REQUEST]);
	}

	public void execute(Database.BatchableContext BC, List<DeliveryPackage__c> scope) {
		for (DeliveryPackage__c pkg : scope) {
			try {
				process(pkg);
			} catch (Exception e) {
				pkg.Message__c = e.getMessage();
			}
		}

		UPDATE scope;
	}

	public void finish(Database.BatchableContext BC) {}

	private void process(DeliveryPackage__c pkg) {
		put(new RoyalMailDelivery.CancelRequest(StringUtil.splitTrim(pkg.TrackingIds__c, ',')));
		pkg.Status__c = DeliveryPackage.STATUS_CANCELLED;
		pkg.Message__c = '';	// Clear any previous error message
	}

	private void put(RoyalMailDelivery.CancelRequest cancelRequest) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:RoyalMail/shipments/status');
		request.setMethod('PUT');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(cancelRequest));

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			RoyalMailDelivery.CancelResponse cancelResponse = (RoyalMailDelivery.CancelResponse)JSON.deserialize(response.getBody(), RoyalMailDelivery.CancelResponse.class);
			String errorMessage = '';
			for (RoyalMailDelivery.Error error : cancelResponse.Errors) {
				errorMessage += error.Message + ' ';
			}
			throw new RoyalMailDelivery.RequestException(errorMessage.trim());
		}
	}
}