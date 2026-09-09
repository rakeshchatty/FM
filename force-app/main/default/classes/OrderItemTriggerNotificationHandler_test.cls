@isTest
public class OrderItemTriggerNotificationHandler_test {
    @isTest
    private static void sendNotification() {
        Account parentAccount = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parentAccount.Id, null);
        
        Suppliers__c supplier = new Suppliers__c();
        supplier.Name = 'Test Supp';
        supplier.Phone_Number__c = '1234567898';
        INSERT supplier;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Order order = new Order(
            AccountId = location.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            Supplier_Status__c = 'Quote Required',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Invoice_Created__c = false,
            Pricebook2Id = pricebookId,
            Supplier__c = supplier.Id
        );
        INSERT order;
        
        Set<Id> orderIds = new Set<Id>();
        orderIds.add(order.Id);
        
        Test.setMock(HttpCalloutMock.class, new MockHttpResponseGenerator());
        Test.startTest();
        OrderItemTriggerNotificationHandler.sendNotification(orderIds);
        Test.stopTest();
    }
    
    public class MockHttpResponseGenerator implements HttpCalloutMock {
        public  HTTPResponse respond(HTTPRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"example":"test"}');
            res.setStatusCode(200);
            return res;
        }
    }
}