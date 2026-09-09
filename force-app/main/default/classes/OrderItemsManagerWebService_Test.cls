@isTest
public class OrderItemsManagerWebService_Test {
    
    @isTest 
    private static void handleOrderItem_Test() {
        Test.startTest();
        Id orderIdObj = createDummyData();
        RestRequest request = new RestRequest();
        request.requestUri =
            'https://' + URL.getSalesforceBaseUrl().getHost() +'/services/apexrest/OrderItem/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"orderIdObject": "orderIdObj","unitPriceObject":129.00}');
        RestContext.request = request;
        // add an order item under specific product
        String orderItemId = OrderItemsManagerWebService.handleOrderItem(orderIdObj, 167.00);
        System.debug('id is::::'+orderItemId);
        // Verify order item has been added
        System.assert(orderItemId != null);
        Test.stopTest();
    }  
    @isTest 
    private static void handleOrderItem_Test2() {
        Test.startTest();
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        Suppliers__c supObj = new Suppliers__c();
        supObj.Name = 'Test Supp';
        supObj.Phone_Number__c = '1234567898';
        INSERT supObj;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Order orderObj = new Order(
            AccountId = locationAccount.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'draft',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Invoice_Created__c = false,
            Pricebook2Id = pricebookId,
            Supplier__c = supObj.Id
        );
        insert orderObj;
        
        //Create your product
        Product2 prod = TestDataHelper.insertProduct('Additional Waste', 'Pro-X', 'Delivery');
        
        Id orderIdObj = orderObj.id;
        RestRequest request = new RestRequest();
        request.requestUri =
                'https://' + URL.getSalesforceBaseUrl().getHost() + '/services/apexrest/OrderItem/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"orderIdObject": "orderIdObj","unitPriceObject":129.00}');
        RestContext.request = request;
        // add an order item under specific product
        String orderItemId = OrderItemsManagerWebService.handleOrderItem(orderIdObj, 167.00);
        System.debug('id is::::'+orderItemId);
        // Verify order item has been added
        System.assert(orderItemId != null);
        Test.stopTest();
    }  
    
    @isTest 
    private static void handleOrderItem_Test4() {
        Test.startTest();
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        Suppliers__c supObj = new Suppliers__c();
        supObj.Name = 'Test Supp';
        supObj.Phone_Number__c = '1234567898';
        INSERT supObj;
        
        Id pricebookId = Test.getStandardPricebookId();
        System.debug('old standard::::::'+pricebookId);
        
        
        //Create your product
        Product2 prod = TestDataHelper.insertProduct('Additional Waste', 'Pro-X', 'Delivery');
        
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        Pricebook2 customPB = new Pricebook2(Name='Custom Pricebook', isActive=true,Effective_Date__c = System.today());
        insert customPB;
        
        Order orderObj = new Order(
            AccountId = locationAccount.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'draft',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Invoice_Created__c = false,
            Pricebook2Id = customPB.Id,
            Supplier__c = supObj.Id
        );
        insert orderObj;
        
        Pricebook2 customPBnew = new Pricebook2(Name='Custom PB', isActive=true,Effective_Date__c = System.today());
        insert customPBnew;
        
        //Create your pricebook entry
        PricebookEntry pbEntry2 = new PricebookEntry(
            Pricebook2Id = customPBnew.Id,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry2;
        RestRequest request = new RestRequest();
        request.requestUri =
            'https://' + URL.getSalesforceBaseUrl().getHost() + '/services/apexrest/OrderItem/';
        request.httpMethod = 'POST';
        request.addHeader('Content-Type', 'application/json');
        request.requestBody = Blob.valueOf('{"orderIdObject": "orderObj.Id","unitPriceObject":129.00}');
        RestContext.request = request;
        // add an order item under specific product
        String orderItemId = OrderItemsManagerWebService.handleOrderItem(orderObj.Id, 167.00);
        System.debug('id is::::'+orderItemId);
        // Verify order item has been added
        System.assert(orderItemId != null);
        Test.stopTest();
    } 
    //helper method
    static ID createDummyData(){
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        Suppliers__c supObj = new Suppliers__c();
        supObj.Name = 'Test Supp';
        supObj.Phone_Number__c = '1234567898';
        INSERT supObj;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Order orderObj = new Order(
            AccountId = locationAccount.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'draft',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Invoice_Created__c = false,
            Pricebook2Id = pricebookId,
            Supplier__c = supObj.Id
        );
        insert orderObj;
        
        //Create your product
        Product2 prod = TestDataHelper.insertProduct('Additional Waste', 'Pro-X', 'Delivery');
        
        //Create your pricebook entry
        PricebookEntry pbEntry = new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100.00,
            IsActive = true
        );
        insert pbEntry;
        return orderObj.Id;
    }
}