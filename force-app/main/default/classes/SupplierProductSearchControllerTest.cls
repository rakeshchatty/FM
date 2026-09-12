@isTest
private class SupplierProductSearchControllerTest {

	@testSetup
	static void setup() {
		Product_Category__c productCategory = TestDataHelper.insertProductCategory('Test Product Category');
		Waste_Category__c  wasteCategory = TestDataHelper.insertWasteCategory('Cardboard Waste', '123456');
		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');
		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		product.WTN_Product__c = 'Season Ticket';
		INSERT product;

		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, product);
		supplierProduct.End_Date__c = System.today().addDays(5);
		UPDATE supplierProduct;

        Region__c region = new Region__c(Name = 'Test 1');
        INSERT region;

		INSERT new Postcode_Supplier__c(Postcode__c = region.Id, Supplier__c = supplier.id);
	}

	@isTest
	static void testCollegetSuppliersWithProductctionSchedules() {
		Id postcodeId = [SELECT Id FROM Region__c].Id;
		Id productId = [SELECT Id FROM Product2].Id;
		List<SupplierProductSearchController.SupplierProductWrapper> supplierProducts = SupplierProductSearchController.getSuppliersWithProduct(postcodeId, productId);
		Assert.areEqual(1, supplierProducts.size());
	}

	@isTest
	static void searchProducts() {
		List<Product2> products = SupplierProductSearchController.searchProducts('Test');
		Assert.areEqual(1, products.size());
	}
}