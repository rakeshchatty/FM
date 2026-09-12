@isTest
private class BinChargeBatchTest {

	@isTest
	static void test() {
        TestDataHelper.insertVat();
		Suppliers__c supplier = TestDataHelper.insertSupplierFirstMile();
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

        Round__c round = TestDataHelper.insertRound(true);
		DailyDispatch__c dispatch = TestDataHelper.insertDispatch(round);
		DispatchLocation__c dispatchLocation = TestDataHelper.insertDispatchLocation(dispatch, location);

        Product_Category__c gwProductCategory = TestDataHelper.insertProductCategory('General Waste GW');
		Product_Category__c dmrProductCategory = TestDataHelper.insertProductCategory('Mixed Recycling DMR');
		Product_Category__c fdProductCategory = TestDataHelper.insertProductCategory('Food');
		Product_Category__c glsProductCategory = TestDataHelper.insertProductCategory('Glass');

		List<Product2> products = new List<Product2>();
		products.add(TestDataHelper.createProduct('Test Product 01', 'TP001', 'Collection', gwProductCategory.Id));
		products[0].ProductCategory__c = 'General Waste';
		products[0].DefaultWeightLimit__c = 75;
        products[0].BinCategoryCode__c = 'GEN1100';

		products.add(TestDataHelper.createProduct('Test Product 02', 'TP002', 'Collection', dmrProductCategory.Id));
		products[1].ProductCategory__c = 'Mixed Recycling';
		products[1].DefaultWeightLimit__c = 75;
        products[1].BinCategoryCode__c = 'MILK240';

		products.add(TestDataHelper.createProduct('General Waste Overweight Charge Product', 'GWOVERWT', 'Collection'));
		products[2].ProductCategory__c = 'General Waste Charge';

		products.add(TestDataHelper.createProduct('Mixed Recycling Overweight Charge Product', 'DMROVERWT', 'Collection'));
		products[3].ProductCategory__c = 'Mixed Recycling Charge';

        products.add(TestDataHelper.createProduct('Test Product 03', 'TP003', 'Collection', dmrProductCategory.Id));
		products[4].ProductCategory__c = 'Mixed Recycling';
		products[4].DefaultWeightLimit__c = 75;
        products[4].BinCategoryCode__c = 'MR1100L';

		products.add(TestDataHelper.createProduct('Test Product 04', 'TP004', 'Collection', fdProductCategory.Id));
		products[5].ProductCategory__c = 'Food';
		products[5].DefaultWeightLimit__c = 100;
		products[5].BinCategoryCode__c = 'FOOD160';

		products.add(TestDataHelper.createProduct('Test Product 05', 'TP005', 'Collection', glsProductCategory.Id));
		products[6].ProductCategory__c = 'Glass';
		products[6].DefaultWeightLimit__c = 50;
		products[6].BinCategoryCode__c = 'GLS240';

		products.add(TestDataHelper.createProduct('Food Overweight Charge Product', 'FOODOVERWT', 'Collection'));
		products[7].ProductCategory__c = 'Food Charge';

		products.add(TestDataHelper.createProduct('Glass Overweight Charge Product', 'GLASSOVER', 'Collection'));
		products[8].ProductCategory__c = 'Glass Charge';
		INSERT products;

		TestDataHelper.insertOverweightSetting(gwProductCategory.Id, dmrProductCategory.Id, products[2].Id, products[3].Id, fdProductCategory.Id, glsProductCategory.Id, products[7].Id, products[8].Id);

		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[0].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[1].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[2].Id, 1));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[3].Id, 1));
        pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[4].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[5].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[6].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[7].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[8].Id, 10));
		INSERT pricebookEntries;

		Date createdDate = System.today() - 1;
		String key1 = Location.Id + '-' + 'GEN1100' + '-' +  String.valueOf(createdDate.year()) + '-' + String.valueOf('0' + createdDate.month()).right(2);
		String key2 = Location.Id + '-' + 'MILK240' + '-' +  String.valueOf(createdDate.year()) + '-' + String.valueOf('0' + createdDate.month()).right(2);
        String key3 = Location.Id + '-' + 'MR1100L' + '-' +  String.valueOf(createdDate.year()) + '-' + String.valueOf('0' + createdDate.month()).right(2);
        String key4 = Location.Id + '-' + 'FOOD160' + '-' +  String.valueOf(createdDate.year()) + '-' + String.valueOf('0' + createdDate.month()).right(2);
        String key5 = Location.Id + '-' + 'GLS240' + '-' +  String.valueOf(createdDate.year()) + '-' + String.valueOf('0' + createdDate.month()).right(2);

		BinWeight__c bin1 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'GEN1100', Kilogram__c = 70, CreatedDate = System.today().addMonths(-1), Key__c = key1, Status__c = 'No match');
		BinWeight__c bin2 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'GEN1100', Kilogram__c = 90, CreatedDate = System.today().addMonths(-1), Key__c = key1, Status__c = 'No match');
		BinWeight__c bin3 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'GEN1100', Kilogram__c = 115, CreatedDate = System.today().addMonths(-1), Key__c = key1, Status__c = 'No match');
		BinWeight__c bin4 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'MILK240', Kilogram__c = 130, CreatedDate = System.today().addMonths(-1), Key__c = key2, Status__c = 'No match');
        BinWeight__c bin5 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'MR1100L', Kilogram__c = 125, CreatedDate = System.today().addMonths(-1), Key__c = key3, Status__c = 'No match');
        BinWeight__c bin6 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'FOOD160', Kilogram__c = 175, CreatedDate = System.today().addMonths(-1), Key__c = key4, Status__c = 'No match');
        BinWeight__c bin7 = new BinWeight__c(Location__c = location.Id, Date__c = createdDate, CategoryCode__c = 'GLS240', Kilogram__c = 95, CreatedDate = System.today().addMonths(-1), Key__c = key5, Status__c = 'No match');
		INSERT new List<BinWeight__c>{bin1, bin2, bin3, bin4, bin5, bin6, bin7};

        List<BinSummary__c> binSummaries = new List<BinSummary__c>();
		binSummaries.add(new BinSummary__c(CreatedDate = createdDate, Key__c = key1, Location__c = location.Id, CategoryCode__c = 'GEN1100', Year__c = String.valueOf(createdDate.year()),
									Month__c = String.valueOf('0' + createdDate.month()).right(2), Waypoints__c = 12, OrderProducts__c = 11, Matched__c = 11, Unmatched__c = 3, UnmatchedOverweight__c = 55));
        binSummaries.add(new BinSummary__c(CreatedDate = createdDate, Key__c = key2, Location__c = location.Id, CategoryCode__c = 'MILK240', Year__c = String.valueOf(createdDate.year()),
									Month__c = String.valueOf('0' + createdDate.month()).right(2), Waypoints__c = 5, OrderProducts__c = 5, Matched__c = 5, Unmatched__c = 1, UnmatchedOverweight__c = 55));
        binSummaries.add(new BinSummary__c(CreatedDate = createdDate, Key__c = key3, Location__c = location.Id, CategoryCode__c = 'MR1100L', Year__c = String.valueOf(createdDate.year()),
									Month__c = String.valueOf('0' + createdDate.month()).right(2), Waypoints__c = 5, OrderProducts__c = 5, Matched__c = 9, Unmatched__c = 1, UnmatchedOverweight__c = 50));
		binSummaries.add(new BinSummary__c(CreatedDate = createdDate, Key__c = key4, Location__c = location.Id, CategoryCode__c = 'FOOD160', Year__c = String.valueOf(createdDate.year()),
									Month__c = String.valueOf('0' + createdDate.month()).right(2), Waypoints__c = 8, OrderProducts__c = 8, Matched__c = 8, Unmatched__c = 1, UnmatchedOverweight__c = 75));
		binSummaries.add(new BinSummary__c(CreatedDate = createdDate, Key__c = key5, Location__c = location.Id, CategoryCode__c = 'GLS240', Year__c = String.valueOf(createdDate.year()),
									Month__c = String.valueOf('0' + createdDate.month()).right(2), Waypoints__c = 3, OrderProducts__c = 3, Matched__c = 3, Unmatched__c = 1, UnmatchedOverweight__c = 45));
        INSERT binSummaries;

        Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, products[4]);
        Collection_Waypoints__c waypoint = TestDataHelper.createWaypoint(location, dispatch, dispatchLocation);
		waypoint.Supplier_Product__c = supplierProduct.Id;
        waypoint.Manual_Price__c = 8;
        INSERT waypoint;

		Test.startTest();
		Database.executeBatch(new BinChargeBatch());
		Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM Order WHERE AccountId = :location.Id].size());
		Assert.areEqual(9, [SELECT Id FROM OrderItem WHERE Location__c = :location.Id].size());

        List<OrderItem> orderItem01 = [SELECT Quantity FROM OrderItem WHERE Product2.Name = 'Test Product 01'];
        Assert.areEqual(1, orderItem01.size());
        Assert.areEqual(2, orderItem01[0].Quantity); //Excess = 11 + 3 - 12 = 2

        List<OrderItem> orderItem02 = [SELECT Quantity FROM OrderItem WHERE Product2.Name = 'Test Product 02'];
        Assert.areEqual(1, orderItem02.size());
        Assert.areEqual(1, orderItem02[0].Quantity); //Excess = 5 + 1 - 5 = 1

        List<OrderItem> orderItem03 = [SELECT Quantity, ListPrice, UnitPrice, TotalPrice FROM OrderItem WHERE Product2.Name = 'Test Product 03'];
        Assert.areEqual(1, orderItem03.size());
        Assert.areEqual(5, orderItem03[0].Quantity); //Excess = 9 + 1 - 5 = 5
        Assert.areEqual(8, orderItem03[0].UnitPrice);
        Assert.areEqual(40, orderItem03[0].TotalPrice); //8 * 5 = 40

        List<OrderItem> orderItem04 = [SELECT Quantity FROM OrderItem WHERE Location__c = :location.Id AND Product2.Name = 'General Waste Overweight Charge Product'];
        Assert.areEqual(1, orderItem04.size());
        Assert.areEqual(55, orderItem04[0].Quantity); //Overweight = 55

        List<OrderItem>	orderItem05 = [SELECT Quantity FROM OrderItem WHERE Location__c = :location.Id AND Product2.Name = 'Mixed Recycling Overweight Charge Product'];
        Assert.areEqual(1, orderItem05.size());
        Assert.areEqual(105, orderItem05[0].Quantity); //Overweight = 50 + 55 = 105

		List<OrderItem> orderItem06 = [SELECT Quantity FROM OrderItem WHERE Product2.Name = 'Test Product 04'];
        Assert.areEqual(1, orderItem06.size());
        Assert.areEqual(1, orderItem06[0].Quantity); //Excess = 8 + 1 - 8 = 1

		List<OrderItem> orderItem07 = [SELECT Quantity FROM OrderItem WHERE Product2.Name = 'Test Product 05'];
        Assert.areEqual(1, orderItem07.size());
        Assert.areEqual(1, orderItem07[0].Quantity); //Excess = 3 + 1 - 3 = 1

		List<OrderItem>	orderItem08 = [SELECT Quantity FROM OrderItem WHERE Location__c = :location.Id AND Product2.Name = 'Food Overweight Charge Product'];
        Assert.areEqual(1, orderItem08.size());
        //Assert.areEqual(105, orderItem08[0].Quantity); //Overweight = 75
		System.debug('orderItem08[0].Quantity: ' + orderItem08[0].Quantity);

		List<OrderItem>	orderItem09 = [SELECT Quantity FROM OrderItem WHERE Location__c = :location.Id AND Product2.Name = 'Glass Overweight Charge Product'];
        Assert.areEqual(1, orderItem09.size());
        //Assert.areEqual(105, orderItem09[0].Quantity); //Overweight = 45
		System.debug('orderItem09[0].Quantity: ' + orderItem09[0].Quantity);

	}
}