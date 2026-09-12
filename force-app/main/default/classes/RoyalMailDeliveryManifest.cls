public without sharing class RoyalMailDeliveryManifest {

	@InvocableMethod (Label = 'Royal Mail Delivery Manifest API')
	public static void process() {
    	RoyalMailDeliveryManifestProcess();
	}

	@future(callout = true)
	private static void RoyalMailDeliveryManifestProcess() {
		RoyalMailDelivery.ManifestRequest manifestRequest = new RoyalMailDelivery.ManifestRequest();
		manifestRequest.ShippingLocationId = RoyalMailSetting__c.getOrgDefaults().ShippingLocationId__c;

		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:RoyalMail/manifests/RM');
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(manifestRequest));

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			RoyalMailDelivery.ManifestResponse manifestResponse = (RoyalMailDelivery.ManifestResponse)JSON.deserialize(response.getBody(), RoyalMailDelivery.ManifestResponse.class);
			String errorMessage = '';
			for (RoyalMailDelivery.Error error : manifestResponse.Errors) {
				errorMessage += error.Message + ' ';
			}
            System.debug('Error Occurred: ' + manifestResponse.Message);
			//throw new RoyalMailDelivery.RequestException(errorMessage.trim());
		}
	}
}