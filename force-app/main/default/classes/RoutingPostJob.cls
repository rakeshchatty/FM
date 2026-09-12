public without sharing abstract class RoutingPostJob {

	protected abstract RoutingRequest createRequest();
	protected abstract void updateJobError(String status, String message);
	protected abstract void processResult(RoutingResponse routingResponse);

	public void postJob() {
		try {
			post();
		} catch (Exception e) {
			updateJobError('Error', e.getMessage());
		}
	}

	private void post() {
		RoutingSetting__c setting = RoutingSetting__c.getOrgDefaults();

		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:RaaS/?licenseId=' + setting.Licence__c);
		request.setMethod('POST');
		request.setHeader('Content-Type', 'application/json');
		request.setBody(JSON.serialize(createRequest()));

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 202) {
			throw new RoutingException(response.getStatusCode() + ' : ' + response.getStatus() + ' : ' + response.getBody());
		}

		processResult((RoutingResponse) JSON.deserialize(response.getBody(), RoutingResponse.class));
	}

	private class RoutingException extends Exception {}
}