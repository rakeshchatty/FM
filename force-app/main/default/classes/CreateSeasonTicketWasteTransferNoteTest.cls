@isTest
public class CreateSeasonTicketWasteTransferNoteTest {
	
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
		INSERT product;

        TestDataHelper.insertSupplier('First Mile Ltd');
        TestDataHelper.insertSupplier('Test Supplier Product');
    }
    
    @isTest
    static void create() {
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
    static void duplicateCheck() {
        String locationId = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' LIMIT 1].Id;
        String supplierId = [SELECT Id FROM Suppliers__c LIMIT 1].Id;
        List<CreateSeasonTicketWasteTransferNote.Input> inputs = new List<CreateSeasonTicketWasteTransferNote.Input>();
        for (Integer i=0; i<5; i++) {
            CreateSeasonTicketWasteTransferNote.Input input = new CreateSeasonTicketWasteTransferNote.Input();
            input.locationId = locationId;
            input.supplierId = supplierId;
            input.startDate = System.today();
            inputs.add(input);
        }

        CreateSeasonTicketWasteTransferNote.create(inputs);
        Assert.areEqual(1, [SELECT Id FROM Compliance_Doc__c].size());
    }
}