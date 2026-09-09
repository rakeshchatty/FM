@isTest
public class ReceivedWaypointTest {

	private static final Date waypointDate = System.today();
	private static final String source = 'RaaS';

	@TestSetup
	static void testData() {
		String timestamp = '2023-05-26 16:53:00';
		Id locatonRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
		Id parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();

		Account parentAccount = new Account(Name='Parent', RecordtypeId=parentRecordTypeId);
		INSERT parentAccount;
		Account location = new Account(Name=source, ParentId=parentAccount.Id, RecordtypeId=locatonRecordTypeId, Price_Book__c = Test.getStandardPricebookId(), Enqix_Dead_Live__c = 'Live');
		INSERT location;
		
		List<Order> orderList = new List<Order>();
		for (Integer i=0; i<7; i++) {
			orderList.add(new Order(AccountId=location.Id, EffectiveDate=System.today(), Status='Draft'));
		}
		INSERT orderList;

		// Queried again to get orders in sequence
		orderList = [SELECT Id FROM Order ORDER BY OrderNumber];
		List<ReceivedWaypoint__c> receivedWaypointList = new List<ReceivedWaypoint__c>();
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 0', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=00, Order__c=orderList[0].Id));
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 1', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=01, Order__c=orderList[1].Id));
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 1', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=02, Order__c=orderList[2].Id));
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 2', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=03, Order__c=orderList[3].Id));
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 2', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=04, Order__c=orderList[4].Id));
		INSERT receivedWaypointList;

		Test.startTest();
		ReceivedWaypointGroup__c waypointGroup = new ReceivedWaypointGroup__c(Date__c=waypointDate, Source__c=source, Timestamp__c=timestamp);
		INSERT waypointGroup;
		Test.stopTest();

		for (ReceivedWaypoint__c receivedWaypoint : receivedWaypointList) {
			Test.setCreatedDate(receivedWaypoint.Id, Datetime.now().addDays(-31));
		}
		Test.setCreatedDate(waypointGroup.Id, Datetime.now().addDays(-31));
	}

	@IsTest
	static void variation1() {
		Assert.areEqual(3, [SELECT Id FROM maps__Route__c].size(), '3 Routes are inserted');
		Assert.areEqual(5, [SELECT Id FROM maps__Waypoint__c].size(), '5 wayspoints are inserted');
		Assert.areEqual(1, [SELECT Id FROM ReceivedWaypointGroup__c WHERE Status__c = 'Complete'].size(), 'Group insertion completed');
		Assert.areEqual(5, [SELECT Id FROM ReceivedWaypoint__c WHERE Status__c = 'Complete'].size(), '5 ReceivedWaypoints are completed');
	}

	@IsTest
	static void  variation2To7() {
		String timestamp = '2023-05-26 16:55:00';
		List<Order> orderList = [SELECT Id FROM Order ORDER BY OrderNumber];
		List<ReceivedWaypoint__c> receivedWaypointList = new List<ReceivedWaypoint__c>();
		// New Route added and New Waypoint
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 3', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=05, Order__c=orderList[5].Id));
		// Route change and Delete Route 0
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 3', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=00, Order__c=orderList[0].Id));
		// Sequnece change
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 1', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=10, Order__c=orderList[1].Id));
		// Route & sequence change
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 3', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=20, Order__c=orderList[2].Id));
		// New waypoint on existing Routes 
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 2', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=03, Order__c=orderList[6].Id));
		// Delete exisitng waypoint
		// receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 2', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=03, Order__c=orderList[3].Id));
		// No change
		receivedWaypointList.add(new ReceivedWaypoint__c(Name='Route 2', Date__c=waypointDate, Timestamp__c=timestamp, Source__c=source, SequenceNumber__c=04, Order__c=orderList[4].Id));
		INSERT receivedWaypointList;

		Test.startTest();
		INSERT new ReceivedWaypointGroup__c(Date__c=waypointDate, Source__c=source, Timestamp__c=timestamp);
		Test.stopTest();

		Assert.areEqual(3, [SELECT Id FROM maps__Route__c].size(), '3 Routes are inserted');
		Assert.areEqual(6, [SELECT Id FROM maps__Waypoint__c].size(), '6 wayspoints are inserted');
		Assert.areEqual(2, [SELECT Id FROM ReceivedWaypointGroup__c WHERE Status__c = 'Complete'].size(), '2 Group insertion completed');
		Assert.areEqual(11, [SELECT Id FROM ReceivedWaypoint__c WHERE Status__c = 'Complete'].size(), '11 ReceivedWaypoints are completed');
	}

	@IsTest
	static void deleteOlderWaypointsTest() {
		Assert.isTrue([SELECT Id FROM ReceivedWaypoint__c].size() != 0, 'Received waypoints are expected to be found');
		Assert.isTrue([SELECT Id FROM ReceivedWaypointGroup__c].size() != 0, 'ReceivedWaypointGroup are expected to be found');

		Test.startTest();
		ReceivedWaypointDeleteBatch.deleteOlderReceivedWaypoints();
		Test.stopTest();

		Assert.isTrue([SELECT Id FROM ReceivedWaypoint__c].size() == 0, 'All Received waypoints are expected to delete');
		Assert.isTrue([SELECT Id FROM ReceivedWaypointGroup__c].size() == 0, 'All ReceivedWaypointGroup are expected to delete');
	}
}