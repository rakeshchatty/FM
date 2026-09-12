@isTest
public class CreateWasteCategoryProductTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Contact contact = TestDataHelper.insertContact(parent.Id, 'FirstMile');
		TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');

		Product_Category__c productCategory = TestDataHelper.insertProductCategory('Test Product Category');
		Waste_Category__c  wasteCategory = TestDataHelper.insertWasteCategory('Cardboard Waste', '123456');
		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');

		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		product.WTN_Product__c = 'Season Ticket';
		INSERT product;

		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);

		List<CreateSeasonTicketWasteTransferNote.Input> inputs = new List<CreateSeasonTicketWasteTransferNote.Input>();
		CreateSeasonTicketWasteTransferNote.Input input = new CreateSeasonTicketWasteTransferNote.Input();
		input.locationId = location.Id;
		input.supplierId = supplier.Id;
		input.startDate = System.today();
		inputs.add(input);

		CreateSeasonTicketWasteTransferNote.create(inputs);
		Assert.areEqual(1, [SELECT Id FROM Compliance_Doc__c].size());
	}

	@isTest
	static void create() {
		Supplier_Product__c supplierProduct = [SELECT Id, Product__c FROM Supplier_Product__c LIMIT 1];
		List<CreateWasteCategoryProduct.Input> inputs = new List<CreateWasteCategoryProduct.Input>();
		CreateWasteCategoryProduct.Input input = new CreateWasteCategoryProduct.Input();
		input.complianceDocumentId = [SELECT Id FROM Compliance_Doc__c LIMIT 1].Id;
		input.productId = supplierProduct.Product__c;
		inputs.add(input);

		CreateWasteCategoryProduct.create(inputs);
		Assert.areEqual(1, [SELECT Id FROM WTN_Waste_Category__c].size());
	}

	@isTest
	static void duplicateCheck() {
		Supplier_Product__c supplierProduct = [SELECT Id, Product__c FROM Supplier_Product__c LIMIT 1];
		String complianceDocumentId = [SELECT Id FROM Compliance_Doc__c LIMIT 1].Id;
		List<CreateWasteCategoryProduct.Input> inputs = new List<CreateWasteCategoryProduct.Input>();
		for (Integer i=0; i<5; i++) {
			CreateWasteCategoryProduct.Input input = new CreateWasteCategoryProduct.Input();
			input.complianceDocumentId = complianceDocumentId;
			input.productId = supplierProduct.Product__c;
			inputs.add(input);
		}

		CreateWasteCategoryProduct.create(inputs);
		Assert.areEqual(1, [SELECT Id FROM WTN_Waste_Category__c].size());
	}
}