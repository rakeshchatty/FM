@isTest
private class RoyalMailDeliveryManifestTest {

	@isTest
	static void sendRequest() {
		TestDataHelper.insertRoyalMailSetting();

		Test.setMock(HttpCalloutMock.class, new Mock());
		Test.startTest();
		RoyalMailDeliveryManifest.process();
		Test.stopTest();
	}

	@isTest
	static void sendManifestErrorRequest() {
		TestDataHelper.insertRoyalMailSetting();

		Test.setMock(HttpCalloutMock.class, new Mock(true));
		Test.startTest();
        RoyalMailDeliveryManifest.process();
		Test.stopTest();
	}

	private class Mock implements HttpCalloutMock {

		Boolean isError = false;

		private Mock() {}

		private Mock(Boolean isError) {
			this.isError = isError;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse response = new HTTPResponse();
			RoyalMailDelivery.ManifestResponse manifestResponse = new RoyalMailDelivery.ManifestResponse();

			if (isError) {
				manifestResponse.Errors = new List<RoyalMailDelivery.Error>{new RoyalMailDelivery.Error()};
				manifestResponse.Errors[0].Message = 'Random error message';
				response.setStatusCode(400);
			} else {
				response.setStatusCode(200);
			}

			response.setBody(JSON.serialize(manifestResponse));
			return response;
		}
	}
}