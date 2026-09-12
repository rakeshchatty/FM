@isTest
private class WtnWasteCategoryOnScheduleTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Contact contact = TestDataHelper.insertContact(parent.Id, 'LastName');
		TestDataHelper.insertAccountContactRelation(location.Id, contact.Id, 'Service Contact');

		Product_Category__c productCategory = TestDataHelper.insertProductCategory('Test Product Category');
		Waste_Category__c  wasteCategory = TestDataHelper.insertWasteCategory('Cardboard Waste', '123456');
		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		product.WTN_Product__c = 'Season Ticket';
		INSERT product;

		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
	}

	@isTest
	static void testCollectionSchedules() {
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' LIMIT 1];
		Suppliers__c supplier = [SELECT Id FROM Suppliers__c LIMIT 1];
		Supplier_Product__c supplierProduct = [SELECT Id FROM Supplier_Product__c LIMIT 1];
		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Tuesday;Wednesday;Thursday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Saturday;Sunday', Time__c = '20:30'));
		Test.startTest();
		INSERT collectionSchedules;
		Test.stopTest();

		Assert.areEqual(6, [SELECT Id FROM Schedule__c].size());
		Id wtnWasteCategoryId = [SELECT Id FROM WTN_Waste_Category__c LIMIT 1].Id;
		for (Schedule__c schedule : [SELECT WtnWasteCategory__c FROM Schedule__c]) {
			Assert.areEqual(wtnWasteCategoryId, schedule.WtnWasteCategory__c);
		}
	}

	@isTest
	static void testWtnWasteCategories() {
		Id locationId = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' LIMIT 1].Id;
		Id supplierId = [SELECT Id FROM Suppliers__c LIMIT 1].Id;
		List<CreateSeasonTicketWasteTransferNote.Input> inputs = new List<CreateSeasonTicketWasteTransferNote.Input>();
		CreateSeasonTicketWasteTransferNote.Input input = new CreateSeasonTicketWasteTransferNote.Input();
		input.locationId = locationId;
		input.supplierId = supplierId;
		input.startDate = System.today();
		inputs.add(input);
		CreateSeasonTicketWasteTransferNote.create(inputs);
		Assert.areEqual(1, [SELECT Id FROM Compliance_Doc__c].size());

		Supplier_Product__c supplierProduct = [SELECT Id, Product__c FROM Supplier_Product__c LIMIT 1];
		List<CreateWasteCategoryProduct.Input> wtnInputs = new List<CreateWasteCategoryProduct.Input>();
		CreateWasteCategoryProduct.Input wtnInput = new CreateWasteCategoryProduct.Input();
		wtnInput.complianceDocumentId = [SELECT Id FROM Compliance_Doc__c LIMIT 1].Id;
		wtnInput.productId = supplierProduct.Product__c;
		wtnInputs.add(wtnInput);
		CreateWasteCategoryProduct.create(wtnInputs);
		Assert.areEqual(1, [SELECT Id FROM WTN_Waste_Category__c].size());

		Schedule__c collectionSchedule = new Schedule__c(Location__c = locationId, Supplier__c = supplierId, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Saturday;Sunday', Time__c = '20:30');
		Test.startTest();
		INSERT collectionSchedule;
		Test.stopTest();

		Assert.areEqual(2, [SELECT Id FROM Schedule__c].size());
		Assert.areEqual([SELECT Id FROM WTN_Waste_Category__c LIMIT 1].Id, [SELECT WtnWasteCategory__c FROM Schedule__c WHERE Id = :collectionSchedule.Id].WtnWasteCategory__c);
	}
}