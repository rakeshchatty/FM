public without sharing class RoyalMailDeliveryPickedBatch implements Database.Batchable<sObject>, Database.AllowsCallouts {
	private Set<Id> packageIds = new Set<Id>();

	public RoyalMailDeliveryPickedBatch(Set<Id> packageIds) {
		this.packageIds = packageIds;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator([SELECT TrackingIds__c FROM DeliveryPackage__c WHERE Id IN :packageIds AND Status__c = :DeliveryPackage.STATUS_PACKAGED]);
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
		put(new RoyalMailDelivery.PickedRequest(StringUtil.splitTrim(pkg.TrackingIds__c, ',')));
		//pkg.Status__c = DeliveryPackage.STATUS_PACKAGED;
		pkg.Message__c = '';	// Clear any previous error message
	}

	private void put(RoyalMailDelivery.PickedRequest pickedRequest) {
		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:RoyalMail/shipments/status');
		request.setMethod('PUT');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(pickedRequest));

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			RoyalMailDelivery.PickedResponse pickedResponse = (RoyalMailDelivery.PickedResponse)JSON.deserialize(response.getBody(), RoyalMailDelivery.PickedResponse.class);
			String errorMessage = '';
			for (RoyalMailDelivery.Error error : pickedResponse.Errors) {
				errorMessage += error.Message + ' ';
			}
			throw new RoyalMailDelivery.RequestException(errorMessage.trim());
		}
	}
}