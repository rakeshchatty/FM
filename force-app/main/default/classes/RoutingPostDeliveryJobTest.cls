@isTest
private class RoutingPostDeliveryJobTest {

	private static final Integer JOB_ID = 1234;
	private static final String ROUTE_NAME = 'Route 001';

	@testSetup
	static void setup() {
		TestDataHelper.insertSupplierFirstMile();

		Depot__c depot = TestDataHelper.insertDepot();
		Integer depotIndex = Convert.toInteger(depot.Index__c);

		DeliveryRouteGroup__c routeGroup = new DeliveryRouteGroup__c();
		INSERT routeGroup;
		DeliveryRoute__c route = new DeliveryRoute__c(DeliveryRouteGroup__c = routeGroup.Id, Name = ROUTE_NAME, StartDepotIndex__c = depotIndex, EndDepotIndex__c = depotIndex,
			StartTime__c = '09:00', MaxRouteTime__c = '11:00', VehicleCapacity__c = 100, Preference__c = 1, SkillSet__c = 'A,V,PM,PMC,WC,SC');
		INSERT route;

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
        Order order = TestDataHelper.insertOrder(location.Id);
		DeliveryOrderGroup__c orderGroup = new DeliveryOrderGroup__c(DeliveryRouteGroup__c = routeGroup.Id);
		INSERT orderGroup;
		DeliveryOrder__c deliveryOrder = new DeliveryOrder__c(DeliveryOrderGroup__c = orderGroup.Id, Demand__c = 10, Order__c = order.Id,
			RouteDate__c = System.today(), ServiceTime__c = 120, ServiceType__c = 'DEL', SkillSet__c = 'SC');
		INSERT deliveryOrder;
	}

	@isTest
	static void postJob() {
		DeliveryOrderGroup__c orderGroup = [SELECT Id FROM DeliveryOrderGroup__c];
		orderGroup.RoutingStatus__c = 'Requested';

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(true));
		UPDATE orderGroup;
		Test.stopTest();

		orderGroup = [SELECT RoutingJobId__c FROM DeliveryOrderGroup__c];
		Assert.areEqual(JOB_ID, orderGroup.RoutingJobId__c);
	}

	@isTest
	static void postJobError() {
		DeliveryOrderGroup__c orderGroup = [SELECT Id FROM DeliveryOrderGroup__c];

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(false));
		System.enqueueJob(new RoutingPostDeliveryJobQueueable(orderGroup.Id));
		Test.stopTest();

		orderGroup = [SELECT RoutingJobId__c, RoutingResponse__c FROM DeliveryOrderGroup__c];
		Assert.areEqual(null, orderGroup.RoutingJobId__c);
	}

    private class Mock implements HttpCalloutMock {

		Boolean isSuccess = true;
		private Mock(Boolean isSuccess) {
			this.isSuccess = isSuccess;
		}

		public HTTPResponse respond(HTTPRequest req) {
            HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'text/json');

			RoutingResponse routingResponse = new RoutingResponse();
			routingResponse.jobId = JOB_ID;
			response.setStatusCode(isSuccess ? 202 : 501);
			response.setBody(JSON.serialize(routingResponse));
            return response;
        }
    }
}