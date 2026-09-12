@isTest
public class CreateWasteCategoryProductPerOrderTest {
    
    @testSetup
    static void setup() {
        Account parent = TestDataHelper.createAccount();
        INSERT parent;
        
        Account location = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact contact = TestDataHelper.insertContact(parent.Id, 'FirstMile');
        
        TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');
        
        Product_Category__c productCategory = new Product_Category__c(Name = 'Test Product Category', Enqix_Id__c = 12345, Product_Category_Key__c = 'Test Product Category Key');
        INSERT productCategory;     
        
        Waste_Category__c  wasteCategory = new Waste_Category__c(Name = 'Cardboard Waste', Codes__c = '123456');
        INSERT wasteCategory;
        
        Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
        
        Product2 product1 = TestDataHelper.createProduct('Test Product1', '1235532', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '265');
        product1.WTN_Product__c = 'Ad-Hoc';
        INSERT product1;
        
        Product2 product2 = TestDataHelper.createProduct('Test Product2', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
        product2.WTN_Product__c = 'Hazardous Consignment Note';
        product2.KG__c = 100;
        INSERT product2;
        
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
        
        Order order = TestDataHelper.insertOrder(location.Id);
        
        PricebookEntry priceBookEntry1 = TestDataHelper.insertStandardPricebookEntry(product1.Id, 60);        
        PricebookEntry priceBookEntry2 = TestDataHelper.insertStandardPricebookEntry(product2.Id, 70);
        
        TestDataHelper.insertOrderItem(order.Id, product1.Id, priceBookEntry1.Id);        
        TestDataHelper.insertOrderItem(order.Id, product2.Id, priceBookEntry2.Id);        
        TestDataHelper.insertOrderItem(order.Id, product2.Id, priceBookEntry2.Id);        
        TestDataHelper.insertOrderItem(order.Id, product1.Id, priceBookEntry1.Id);
        
        order.Status = 'Delivered';
        UPDATE order;
        
        Compliance_Doc__c AdHocComplianceDoc = new Compliance_Doc__c();
        AdHocComplianceDoc.Name = 'Ad-Hoc';
        AdHocComplianceDoc.Account__c = location.Id;
        AdHocComplianceDoc.Order__c = order.Id;
        INSERT AdHocComplianceDoc;  
        
        Compliance_Doc__c HazComplianceDoc = new Compliance_Doc__c();
        HazComplianceDoc.Name = 'Hazardous';
        HazComplianceDoc.Account__c = location.Id;
        HazComplianceDoc.Order__c = order.Id;
        INSERT HazComplianceDoc;
        
    }
    
    @isTest
    static void create() {
        List<CreateWasteCategoryProductPerOrder.Input> inputs = new List<CreateWasteCategoryProductPerOrder.Input>();
        CreateWasteCategoryProductPerOrder.Input AdHocInput = new CreateWasteCategoryProductPerOrder.Input();
        AdHocInput.complianceDocumentId = [SELECT Id FROM Compliance_Doc__c WHERE Name = 'Ad-Hoc' LIMIT 1].Id;
        AdHocInput.orderId = [SELECT Id FROM Order LIMIT 1].Id;
        AdHocInput.wtnProduct = 'Ad-Hoc';
        inputs.add(AdHocInput);
        
        CreateWasteCategoryProductPerOrder.Input HazInput = new CreateWasteCategoryProductPerOrder.Input();
        HazInput.complianceDocumentId = [SELECT Id FROM Compliance_Doc__c WHERE Name = 'Hazardous' LIMIT 1].Id;
        HazInput.orderId = [SELECT Id FROM Order LIMIT 1].Id;
        HazInput.wtnProduct = 'Hazardous Consignment Note';
        inputs.add(HazInput);
        
        CreateWasteCategoryProductPerOrder.create(inputs);
        List<WTN_Waste_Category__c> wtn = [SELECT Id, Weight__c FROM WTN_Waste_Category__c];
        Assert.areEqual(2, [SELECT Id FROM WTN_Waste_Category__c].size());
    }    
}