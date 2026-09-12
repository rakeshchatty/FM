@isTest
private class WtnWasteCategorySummaryBatchTest {

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

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '18:00', Start_Date__c = Date.today().addDays(1)));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 20,
												Days__c = 'Tuesday;Wednesday;Thursday', Time__c = '18:00', End_Date__c = Date.today().addDays(-1)));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 40,
												Days__c = 'Saturday;Sunday', Time__c = '20:30', Start_Date__c = Date.today()));
		INSERT collectionSchedules;
	}

	@isTest
	static void testWtnWasteCategorySummaryBatch() {
		Test.startTest();
		new WtnWasteCategorySummaryScheduler().execute(null);
		Test.stopTest();
		Assert.areEqual(80, [SELECT Quantity__c FROM WTN_Waste_Category__c LIMIT 1].Quantity__c);
	}

	@isTest
	static void testQuantityOnWtnWasteCategory() {
		Schedule__c schedule = [SELECT Id,Start_Date__c FROM Schedule__c WHERE Time__c = '18:00' AND End_Date__c = null LIMIT 1];
		schedule.Start_Date__c = Date.today();
		UPDATE schedule;

		Test.startTest();
		new WtnWasteCategorySummaryScheduler().execute(null);
		Test.stopTest();
		Assert.areEqual(90, [SELECT Quantity__c FROM WTN_Waste_Category__c LIMIT 1].Quantity__c);
	}
}