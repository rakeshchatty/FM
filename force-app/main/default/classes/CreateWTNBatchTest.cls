@isTest
private class CreateWTNBatchTest {

	@testSetup
	static void testCreateWTNBatch() {
		Test.setMock(HttpCalloutMock.class, new DoogalTest.RestMock('N12	51.6154	-0.178479'));

		Account parentAccount = TestDataHelper.createAccount();
		parentAccount.BillingStreet = 'BillingStreet';
		parentAccount.BillingPostalcode = 'N20 CPW';
		parentAccount.BillingCountry = 'United Kingdom';
		INSERT parentAccount;

		Account location = TestDataHelper.createLocation(parentAccount.Id, null);
		location.Broker_Cleaner__c = true;
		INSERT location;
        
		Test.startTest();
        TestDataHelper.insertContact(location.Id, 'lastName');
        Test.stopTest();
		
        List<AccountContactRelation> acrs = [SELECT Id FROM AccountContactRelation];
        for (AccountContactRelation acr : acrs) {
            acr.Roles = 'Service Contact';
        }
        UPDATE acrs;
	        
		Waste_Category__c  wasteCategory = new Waste_Category__c(Name = 'Cardboard Waste', Codes__c = '123456');
		INSERT wasteCategory;
		Product2 product = TestDataHelper.createProduct('Test 1', '12345', 'Collection');
		product.WTN_Product__c = 'Season Ticket';
		product.Waste_Category__c = wasteCategory.Id;
		INSERT product;

		PricebookEntry pricebookEntry = new PricebookEntry(
			Pricebook2Id = Test.getStandardPricebookId(),
			Product2Id = product.Id,
			UnitPrice = 100,
			IsActive = true
		);
		INSERT pricebookEntry;

		Suppliers__c s = new Suppliers__c();
		s.Name = 'First Mile Ltd';
		s.Enqix_ID__c = 23;
		s.Phone_Number__c = '123423';
		s.Address__c = 'supplier Address';
		s.Postcode__c = 'N20 TC2';
		INSERT s;

		Supplier_Product__c sp = new Supplier_Product__c();
		sp.Name = 'test';
		sp.Product__c = product.Id;
		sp.Enqix_UID__c = 'test';
		sp.Enqix_Pk__c = 1;
		sp.Supplier__c = s.id;
		INSERT sp;
	}

	@isTest
	private static void test1() {
		Account account = [SELECT Id FROM Account WHERE RecordType.Name = 'Location'];
        INSERT new Contact(FirstName = 'FirstName', LastName = 'LastName', Email = 'test@test.com', AccountId = account.Id);
		Product2 product = [SELECT Id FROM Product2 LIMIT 1];
		Suppliers__c supplier = [SELECT Id FROM Suppliers__c LIMIT 1];
		Supplier_Product__c supplierProduct = [SELECT Id FROM Supplier_Product__c LIMIT 1];

		Schedule__c sc = new Schedule__c();
		sc.Collection_Note__c = 'Collection Note';
		sc.Days__c = 'Monday';
		sc.List_Price__c = 500;
		sc.Location__c = account.Id;
		sc.Price_Book__c = Test.getStandardPricebookId();
		sc.Product__c = product.Id;
		sc.Time__c = '07:45';
		sc.Collection_Quantity__c = 1;
		sc.Supplier__c = supplier.Id;
		sc.Supplier_Product__c = supplierProduct.Id;
		sc.start_Date__c = System.today().addYears(-1);
		INSERT sc;
		Test.setCreatedDate(sc.Id, Datetime.now().addMonths(1).addYears(-1));

		Test.startTest();
		Database.executeBatch(new CreateWTNBatch());
		Test.stopTest();

		List<SeasonTicketWTN__c> cd2 = [SELECT Id, StartDate__c FROM SeasonTicketWTN__c ORDER BY CreatedDate DESC];
		Assert.areEqual(1, cd2.size());
		Assert.areEqual(System.today().addYears(-1).year(), cd2[0].StartDate__c.year());
	}

	@isTest
	static void testGetStartDate() {
		Assert.areEqual(System.today(), CreateWTNBatch.getStartDate(System.today()));
		Assert.areEqual(System.today().addMonths(-1), CreateWTNBatch.getStartDate(System.today().addMonths(-1)));
		Assert.areEqual(System.today().addMonths(1).addYears(-1), CreateWTNBatch.getStartDate(System.today().addMonths(1)));
		Date decemberDate = Date.newInstance(System.today().year(), 12, System.today().day());
		Assert.areEqual(decemberDate.addYears(-1), CreateWTNBatch.getStartDate(decemberDate));
	}
}