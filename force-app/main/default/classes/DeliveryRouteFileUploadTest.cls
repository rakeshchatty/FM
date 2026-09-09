@isTest
public with sharing class DeliveryRouteFileUploadTest {
    
    @isTest
    static void testProcess() {
        
        List<Map<Object, Object>> rows = new List<Map<Object, Object>>();
        Map<Object, Object> row1 = new Map<Object, Object>{
            'routeId'=>'B1 180324',
			'startTime' => '08:00:00',
			'maxRouteTime' => '18:00:00',
			'vehicleCapacity' => 1000,
            'startLocation' => 2,
			'rtePref' => 1,
            'skillSetProperties' => 'B'
        };
        Map<Object, Object> row2 = new Map<Object, Object>{
            'routeId'=>'B2 180324',
			'startTime' => '09:00:00',
			'maxRouteTime' => '18:00:00',
			'vehicleCapacity' => 2000,
            'startLocation' => 3,
			'rtePref' => 4,
            'skillSetProperties' => 'Ag'
        };
        rows.add(row1);
        rows.add(row2);
        String delimiter = FileUploadController.getDelimiter('DeliveryRoute');
        String previewText = FileUploadController.preview('DeliveryRoute', rows);
        Test.startTest();
        FileUploadController.process('DeliveryRoute', rows);
        Test.stopTest();
        List<DeliveryRoute__c> deliveryRoutes = [SELECT Name, RtePref__c, SkillSet__c, StartLocation__c, StartTime__c, VehicleCapacity__c FROM DeliveryRoute__c];
        Assert.areEqual(2, deliveryRoutes.size());
        List<DeliveryRouteGroup__c> deliveryRouteGroup = [SELECT Id FROM DeliveryRouteGroup__c];
        Assert.areEqual(1, deliveryRouteGroup.size());
    }
}