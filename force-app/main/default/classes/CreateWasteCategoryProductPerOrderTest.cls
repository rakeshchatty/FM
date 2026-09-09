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
        
        Product2 AdHocProduct = TestDataHelper.createProduct('Test Product1', '1235532', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '265');
        AdHocProduct.WTN_Product__c = 'Ad-Hoc';
        INSERT AdHocProduct;
        
        Product2 HazProduct = TestDataHelper.createProduct('Test Product2', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
        HazProduct.WTN_Product__c = 'Hazardous Consignment Note';
        INSERT HazProduct;
        
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
        
        Order order = TestDataHelper.insertOrder(location.Id);
        
        PricebookEntry priceBookEntry1 = TestDataHelper.insertStandardPricebookEntry(AdHocProduct.Id, 60);        
        PricebookEntry priceBookEntry2 = TestDataHelper.insertStandardPricebookEntry(HazProduct.Id, 70);
        
       	TestDataHelper.insertOrderItem(order.Id, AdHocProduct.Id, priceBookEntry1.Id);        
        TestDataHelper.insertOrderItem(order.Id, AdHocProduct.Id, priceBookEntry1.Id);        
        TestDataHelper.insertOrderItem(order.Id, HazProduct.Id, priceBookEntry2.Id);
        
        order.Status = 'Delivered';
        UPDATE order;
        
        Compliance_Doc__c complianceDoc = new Compliance_Doc__c();
        complianceDoc.Name = 'Ad-Hoc';
        complianceDoc.Account__c = location.Id;
        complianceDoc.Order__c = order.Id;
        INSERT complianceDoc;      
    }
    
    @isTest
    static void create() {
        List<CreateWasteCategoryProductPerOrder.Input> inputs = new List<CreateWasteCategoryProductPerOrder.Input>();
        CreateWasteCategoryProductPerOrder.Input input = new CreateWasteCategoryProductPerOrder.Input();
        input.complianceDocumentId = [SELECT Id FROM Compliance_Doc__c LIMIT 1].Id;
        input.orderId = [SELECT Id FROM Order LIMIT 1].Id;
        input.wtnProduct = 'Ad-Hoc';
        inputs.add(input);
        
        CreateWasteCategoryProductPerOrder.create(inputs);
        Assert.areEqual(1, [SELECT Id FROM WTN_Waste_Category__c].size());
    }    
}