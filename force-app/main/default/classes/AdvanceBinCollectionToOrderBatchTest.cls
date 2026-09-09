@isTest
public class AdvanceBinCollectionToOrderBatchTest {

	@testSetup
	private static void setup() {
		Product_Category__c productCategory = new Product_Category__c(Name = 'Test Product Category', Enqix_Id__c = 12345, Product_Category_Key__c = 'Test Product Category Key');
		INSERT productCategory;

		Waste_Category__c  wasteCategory = new Waste_Category__c(Name = 'Cardboard Waste', Codes__c = '123456');
		INSERT wasteCategory;

		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');

		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		INSERT product;

		Suppliers__c supplier = new Suppliers__c(Name = 'First Mile Ltd', Phone_Number__c = '123456789');
		INSERT supplier;

		Supplier_Product__c supplierProduct = new Supplier_Product__c(Name = 'Test Supplier Product', Supplier__c = supplier.Id, Product__c = product.Id, Enqix_UID__c = '1233');
		INSERT supplierProduct;

		Account parent = TestDataHelper.createAccount();
		parent.IsBinCollectionAdvanceInvoiced__c = true;
		INSERT parent;
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.Id, Supplier__c = supplier.Id, Supplier_Product__c = supplierProduct.Id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.Id, Supplier__c = supplier.Id, Supplier_Product__c = supplierProduct.Id, Collection_Quantity__c = 10,
												Days__c = 'Tuesday;Wednesday;Thursday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.Id, Supplier__c = supplier.Id, Supplier_Product__c = supplierProduct.Id, Collection_Quantity__c = 10,
												Days__c = 'Saturday;Sunday', Time__c = '20:30'));
		INSERT collectionSchedules;
	}

	@isTest
	static void createAdvanceBinInvoices() {
		Test.startTest();
		new AdvanceBinCollectionToOrderSchedular(true).execute(null);
		Test.stopTest();
	}

	@isTest
	static void createAdvanceBinInvoicesForDelta() {
		Schedule__c schedule = [SELECT Id, Location__c FROM Schedule__c LIMIT 1];
		ScheduleAdvanceInvoiceHistory__c scheduleHistory = new ScheduleAdvanceInvoiceHistory__c(Schedule__c = schedule.Id, Location__c = schedule.Location__c, Quantity__c = 05);
		INSERT scheduleHistory;
		Test.setCreatedDate(scheduleHistory.Id, System.now() - 1);

		Test.startTest();
		new AdvanceBinCollectionToOrderSchedular(true).execute(null);
		Test.stopTest();
	}
}