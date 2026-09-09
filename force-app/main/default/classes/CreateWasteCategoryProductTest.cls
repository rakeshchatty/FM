@isTest
public class CreateWasteCategoryProductTest {
	
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

		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		product.WTN_Product__c = 'Season Ticket';
        INSERT product;

        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');

        Supplier_Product__c supplierProduct = new Supplier_Product__c(Name = 'Test Supplier Product', Supplier__c = supplier.Id, Product__c = product.Id, Enqix_UID__c = '1233');
        INSERT supplierProduct;
        
        List<CreateSeasonTicketWasteTransferNote.Input> inputs = new List<CreateSeasonTicketWasteTransferNote.Input>();
        CreateSeasonTicketWasteTransferNote.Input input = new CreateSeasonTicketWasteTransferNote.Input();
        input.locationId = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' LIMIT 1].Id;
        input.supplierId = [SELECT Id FROM Suppliers__c LIMIT 1].Id;
        input.startDate = System.today();
        inputs.add(input);

        CreateSeasonTicketWasteTransferNote.create(inputs);
        Assert.areEqual(1, [SELECT Id FROM Compliance_Doc__c].size());
    }
    
    @isTest
    static void create() {
        List<CreateWasteCategoryProduct.Input> inputs = new List<CreateWasteCategoryProduct.Input>();
        CreateWasteCategoryProduct.Input input = new CreateWasteCategoryProduct.Input();
        input.complianceDocumentId = [SELECT Id FROM Compliance_Doc__c LIMIT 1].Id;
        input.productId = [SELECT Id, Product__c FROM Supplier_Product__c LIMIT 1].Product__c;
        inputs.add(input);

        CreateWasteCategoryProduct.create(inputs);
        Assert.areEqual(1, [SELECT Id FROM WTN_Waste_Category__c].size());
    }
    
    @isTest
    static void duplicateCheck() {
        String complianceDocumentId = [SELECT Id FROM Compliance_Doc__c LIMIT 1].Id;
        String productId = [SELECT Product__c FROM Supplier_Product__c LIMIT 1].Product__c;
        List<CreateWasteCategoryProduct.Input> inputs = new List<CreateWasteCategoryProduct.Input>();
        for (Integer i=0; i<5; i++) {
            CreateWasteCategoryProduct.Input input = new CreateWasteCategoryProduct.Input();
            input.complianceDocumentId = complianceDocumentId;
            input.productId = productId;
            inputs.add(input);
        }

        CreateWasteCategoryProduct.create(inputs);
        Assert.areEqual(1, [SELECT Id FROM WTN_Waste_Category__c].size());
    }
}