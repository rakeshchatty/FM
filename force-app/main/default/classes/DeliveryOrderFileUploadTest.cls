@isTest
public with sharing class DeliveryOrderFileUploadTest {
    @testSetup
	static void testSetup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
        Order order = TestDataHelper.insertOrder(location.Id);
    }
    @isTest
    static void testProcess() {
        Order order = [SELECT Id from Order LIMIT 1];
        System.debug('order.Id'+ order.Id);
        List<Map<Object, Object>> rows = new List<Map<Object, Object>>();
        Map<Object, Object> row1 = new Map<Object, Object>{
            'OrderId' => order.Id,
            'Service Time' => '516',
            'Demand' => '100',
            'serviceType' => 'DEL',
            'RouteDate' => '03/18/2024',
            'SkillSetProperty' => 'WC'
        };
        Map<Object, Object> row2 = new Map<Object, Object>{
            'OrderId' => order.Id,
            'Service Time' => '215',
            'Demand' => '150',
            'serviceType' => 'REM',
            'RouteDate' => '04/20/2024 0:00',
            'SkillSetProperty' => 'V'
        };
        rows.add(row1);
        rows.add(row2);
        FileUploadController.getDelimiter('DeliveryOrder');
		FileUploadController.preview('DeliveryOrder', rows);
		Test.startTest();
		FileUploadController.process('DeliveryOrder', rows);
		Test.stopTest();
        List<DeliveryOrder__c> deliveryOrders = [SELECT Order__c, ServiceTime__c, Demand__c, ServiceType__c, RouteDate__c, SkillSet__c, DeliveryOrderGroup__c 
                                                 FROM DeliveryOrder__c
                                                 WHERE Order__c =: order.Id];
        Assert.areEqual(2, deliveryOrders.size()); 
        List<DeliveryOrderGroup__c> deliveryOrderGroups = [SELECT Id FROM DeliveryOrderGroup__c];
        Assert.areEqual(1, deliveryOrderGroups.size());
    }
}