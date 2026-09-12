@isTest
private class RoutingGetDeliveryResultTest {

	private static final Integer JOB_ID = 1234;
	private static final String ROUTE_NAME = 'Route 001';

	@testSetup
	static void setup() {
		TestDataHelper.insertRoutingSetting();
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
        List<Order> orders = new List<Order>();
		orders.add(TestDataHelper.createOrder(location.Id, System.today()));
		orders.add(TestDataHelper.createOrder(location.Id, System.today()));
		orders.add(TestDataHelper.createOrder(location.Id, System.today()));
		INSERT orders;

		DeliveryOrderGroup__c orderGroup = new DeliveryOrderGroup__c(DeliveryRouteGroup__c = routeGroup.Id, RoutingJobId__c = JOB_ID);
		INSERT orderGroup;
		List<DeliveryOrder__c> deliveryOrders = new List<DeliveryOrder__c>();
		deliveryOrders.add(new DeliveryOrder__c(DeliveryOrderGroup__c = orderGroup.Id, Demand__c = 10, Order__c = orders[0].Id,
			RouteDate__c = System.today(), ServiceTime__c = 120, ServiceType__c = 'DEL', SkillSet__c = 'SC'));
		deliveryOrders.add(new DeliveryOrder__c(DeliveryOrderGroup__c = orderGroup.Id, Demand__c = 10, Order__c = orders[1].Id,
			RouteDate__c = System.today(), ServiceTime__c = 120, ServiceType__c = 'DEL', SkillSet__c = 'SC'));
		deliveryOrders.add(new DeliveryOrder__c(DeliveryOrderGroup__c = orderGroup.Id, Demand__c = 10, Order__c = orders[2].Id,
			RouteDate__c = System.today(), ServiceTime__c = 120, ServiceType__c = 'DEL', SkillSet__c = 'SC'));
		INSERT deliveryOrders;
	}

	@isTest
	static void getResultRouting() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock('Routing'));
		System.enqueueJob(new RoutingGetDeliveryResultQueueable(JOB_ID));
		Test.stopTest();

		DeliveryOrderGroup__c orderGroup = [SELECT RoutingStatus__c, RoutingPollCount__c FROM DeliveryOrderGroup__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('New', orderGroup.RoutingStatus__c);
		Assert.areEqual(1, orderGroup.RoutingPollCount__c);
	}

	@isTest
	static void getResultPollCountExceeded() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock('Routing'));
		System.enqueueJob(new RoutingGetDeliveryResultQueueable(JOB_ID, 2));
		Test.stopTest();

		DeliveryOrderGroup__c orderGroup = [SELECT RoutingStatus__c, RoutingPollCount__c FROM DeliveryOrderGroup__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('Stuck', orderGroup.RoutingStatus__c);
		Assert.areEqual(2, orderGroup.RoutingPollCount__c);
	}

	@isTest
	static void getResultError() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(false));
		System.enqueueJob(new RoutingGetDeliveryResultQueueable(JOB_ID));
		Test.stopTest();

		DeliveryOrderGroup__c orderGroup = [SELECT RoutingStatus__c, RoutingResponse__c FROM DeliveryOrderGroup__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('Error', orderGroup.RoutingStatus__c);
		Assert.isTrue(orderGroup.RoutingResponse__c.contains('501'));
	}

	@isTest
	static void getResultUnknownStatus() {
		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock('Unknown Status'));
		System.enqueueJob(new RoutingGetDeliveryResultQueueable(JOB_ID));
		Test.stopTest();

		DeliveryOrderGroup__c orderGroup = [SELECT RoutingStatus__c, RoutingResponse__c FROM DeliveryOrderGroup__c WHERE RoutingJobId__c = :JOB_ID];
		Assert.areEqual('Error', orderGroup.RoutingStatus__c);
		Assert.isTrue(orderGroup.RoutingResponse__c.contains('Unknown Status'));
	}

	@isTest
	static void getResultComplete() {
		List<Order> orders = [SELECT OrderNumber FROM Order LIMIT 3];
		List<RoutingResponse.ServiceLocation> serviceLocations = new List<RoutingResponse.ServiceLocation>();
		for (Order order : orders) {
			RoutingResponse.ServiceLocation serviceLocation = new RoutingResponse.ServiceLocation();
			serviceLocation.recordID = Convert.toInteger(order.OrderNumber);
			serviceLocation.route = ROUTE_NAME;
			serviceLocations.add(serviceLocation);
		}
		serviceLocations[0].sequence = 5;
		serviceLocations[1].sequence = 6;
		serviceLocations[2].sequence = 2;

		Test.startTest();
		Test.setMock(HttpCalloutMock.class, new Mock(serviceLocations));
		System.enqueueJob(new RoutingGetDeliveryResultQueueable(JOB_ID));
		Test.stopTest();

		DeliveryOrderGroup__c orderGroup = [SELECT Id, RoutingStatus__c, RoutingPollCount__c FROM DeliveryOrderGroup__c WHERE RoutingJobId__c = :JOB_ID];
		DeliveryOrder__c deliveryOrder = [SELECT DeliveryRoute__r.Name, SequenceNumber__c FROM DeliveryOrder__c WHERE DeliveryOrderGroup__c = :orderGroup.Id ORDER BY SequenceNumber__c LIMIT 1];
		Assert.areEqual('Completed', orderGroup.RoutingStatus__c);
		Assert.areEqual(ROUTE_NAME, deliveryOrder.DeliveryRoute__r.Name);
		Assert.areEqual(1, deliveryOrder.SequenceNumber__c);
	}

	private class Mock implements HttpCalloutMock {

		Boolean isSuccess = true;
		String status = 'Complete';
		List<RoutingResponse.ServiceLocation> serviceLocations;

		private Mock(Boolean isSuccess) {
			this.isSuccess = isSuccess;
		}
		private Mock(String status) {
			this.status = status;
		}
		private Mock(List<RoutingResponse.ServiceLocation> serviceLocations) {
			this.serviceLocations = serviceLocations;
		}

		public HTTPResponse respond(HTTPRequest req) {
			HTTPResponse response = new HTTPResponse();
			response.setHeader('Content-Type', 'text/json');

			RoutingResponse routingResponse = new RoutingResponse();
			routingResponse.jobId = JOB_ID;
			routingResponse.status = status;
			routingResponse.serviceLocations = serviceLocations;
			response.setStatusCode(isSuccess ? 200 : 501);
			response.setBody(JSON.serialize(routingResponse));
			return response;
		}
	}
}