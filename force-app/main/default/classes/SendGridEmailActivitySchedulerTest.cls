@isTest
private class SendGridEmailActivitySchedulerTest {

	@testSetup
	static void testData() {
		Account parentAccount = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parentAccount.Id, Null);
		TestDataHelper.insertContact(location.Id, 'Contact');
	}

	@isTest
	static void testScheduler() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new SendGridHttpMockResponse());
		new SendGridEmailActivityScheduler().execute(null);
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM Email_Activity__c].size(), 'Email activity should be created');
        System.assertEquals([SELECT Id FROM Contact WHERE Email = 'testcontact@fm.com'].Id, [SELECT Email_Sent_To__c FROM Email_Activity__c].Email_Sent_To__c, 'Email sent to should match the contact');
	}


	@isTest
	static void testBouncedSuppresionMessages() {
		Test.setMock(HttpCalloutMock.class, new SendGridHttpMockResponse());
		System.enqueueJob(new SendGridGetMessageQueueable());

		Test.startTest();
		System.enqueueJob(new SendGridGetSuppressionQueueable());
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM Email_Activity__c WHERE Event__c = 'bounces'].size(), 'Email activity should have bounced event');
	}

	@isTest
	static void testBlockedSuppresionMessages() {
		Test.setMock(HttpCalloutMock.class, new SendGridHttpMockResponse());
		System.enqueueJob(new SendGridGetMessageQueueable());

		Test.startTest();
		System.enqueueJob(new SendGridGetSuppressionQueueable('blocks'));
		Test.stopTest();

		System.assertEquals(1, [SELECT Id FROM Email_Activity__c WHERE Event__c = 'blocks'].size(), 'Email activity should have blocked event');
	}

	private class SendGridHttpMockResponse implements HttpCalloutMock {
		public HttpResponse respond(HttpRequest request) {
			String url = request.getEndpoint();
			String mockResponse;
			if (url.contains('offset')) {
				// Suppresion response
				mockResponse = '[{"email": "testcontact@fm.com", "reason": "Spam"}]';
			} else {
				//Get messages response
				mockResponse = '{"messages":[{"msg_id":"12346","from_email":"customers@thefirstmile.co.uk","to_email":"testcontact@fm.com","subject":"Test Subject 2","status":"delivered","last_event_time":"2025-04-12T01:00:00.000Z"}]}';
			}

			HttpResponse response = new HttpResponse();			
			response.setBody(mockResponse);
			response.setStatusCode(200);
			return response;
		}
	}
}