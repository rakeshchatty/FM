@isTest
private class DeliveryOrderGroupTriggerHandlerTest {
    @testSetup
    static void setup() {
        DeliveryOrderGroup__c deliveryOrderGroup = new DeliveryOrderGroup__c();
        deliveryOrderGroup.Status__c = 'New';
        insert deliveryOrderGroup;
        Account acc = TestDataHelper.createAccount();
        insert acc;

        List<Account> locations = TestDataFactory.createLocations(new List<Account>{acc}, 'test', 10);

        List<Order> orders = new List<Order>();
        for (Integer i = 0; i < 10; i++) {
            orders.add(TestDataHelper.createOrder(locations[i].Id, System.today()));
        }
        INSERT orders;

        List<DeliveryOrder__c> deliveryOrders = new List<DeliveryOrder__c>();
        for (Integer i = 0; i < 10; i++) {
            deliveryOrders.add(new DeliveryOrder__c(Order__c = orders[i].Id, ServiceTime__c = 360.00, Demand__c = 3260.00, ServiceType__c = 'DEL', SkillSet__c = 'C', DeliveryOrderGroup__c = deliveryOrderGroup.Id, RouteDate__c = System.today()));
        }
        INSERT deliveryOrders;

    }

    @isTest static void testMethod1() {
        DeliveryOrderGroup__c deliveryOrderGroup = [SELECT Id FROM DeliveryOrderGroup__c WHERE Status__c = 'New' LIMIT 1];
        deliveryOrderGroup.Status__c = 'Requested';
        UPDATE deliveryOrderGroup;
    }

}