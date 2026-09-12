@isTest
private class SeasonTicketWtnRenewalTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Product_Category__c productCategory = TestDataHelper.insertProductCategory('Test Product Category');
		Waste_Category__c  wasteCategory = TestDataHelper.insertWasteCategory('Cardboard Waste', '123456');
		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		product.WTN_Product__c = 'Season Ticket';
		INSERT product;

		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Tuesday;Wednesday;Thursday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Saturday;Sunday', Time__c = '20:30'));
		INSERT collectionSchedules;

		List<CreateSeasonTicketWasteTransferNote.Input> inputs = new List<CreateSeasonTicketWasteTransferNote.Input>();
		CreateSeasonTicketWasteTransferNote.Input input = new CreateSeasonTicketWasteTransferNote.Input();
		input.locationId = location.Id;
		input.supplierId = supplier.Id;
		input.startDate = System.today();
		inputs.add(input);

		List<Id> wtnIds = CreateSeasonTicketWasteTransferNote.create(inputs);
		UPDATE new Compliance_Doc__c(Id = wtnIds[0], EndDate__c = System.today() - 1);
	}

	@isTest
	static void renew() {
		Test.startTest();
		new SeasonTicketWtnRenewalScheduler().execute(null);
		Test.stopTest();
	}
}