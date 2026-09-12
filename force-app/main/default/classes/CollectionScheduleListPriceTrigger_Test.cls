@isTest
public class CollectionScheduleListPriceTrigger_Test {

	@testSetup
	static void setupTestData() {

		List <RecordType> accRecordTypes = [SELECT Id,
											Name
											FROM RecordType
											WHERE SObjectType = 'Account'
											AND (Name = 'Location' OR Name = 'Partner')
										   ];

		Id locationRecordTypeId;
		Id partnerRecordTypeId;
		Id parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();

		for(RecordType rec : accRecordTypes) {
			if(rec.Name == 'Location') {
				locationRecordTypeId = rec.Id;
			} else if(rec.Name == 'Partner') {
				partnerRecordTypeId = rec.Id;
			}
		}

		Product_Category__c productCat = new Product_Category__c();
		productCat.Name = 'Cardboard';
		insert productCat;

		Product_Skin__c productSkin = new Product_Skin__c();
		productSkin.Name = 'Collection Skin';
		insert productSkin;

		product2 productRec = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection', productCat.Id);
		productRec.Product_Skins__c = productSkin.Id;
		UPDATE productRec;

		priceBook2 priceBookRec = new priceBook2();
		priceBookRec.Name = 'Standard Price Book';
		priceBookRec.IsActive = true;
		pricebookRec.Effective_Date__c=System.Today();
		insert priceBookRec;

		PricebookEntry priceBookEntryRec = new  PricebookEntry();
		priceBookEntryRec.Product2Id = productRec.Id;
		priceBookEntryRec.Pricebook2Id = Test.getStandardPricebookId();
		priceBookEntryRec.UnitPrice = 100;
		priceBookEntryRec.UseStandardPrice = false;
		insert priceBookEntryRec;

		PricebookEntry priceBookEntryRec2 = new  PricebookEntry();
		priceBookEntryRec2.Product2Id = productRec.Id;
		priceBookEntryRec2.Pricebook2Id = priceBookRec.Id;
		priceBookEntryRec2.UnitPrice = 500;
		priceBookEntryRec2.UseStandardPrice = false;
		insert priceBookEntryRec2;

		List<Account> accToInsert = new List<Account>();

		Account parentAcc = TestDataHelper.createAccount();
		INSERT parentAcc;
		Account locationAcc = TestDataHelper.createLocation(parentAcc.Id, Null);
		INSERT locationAcc;
		Account partnerAcc = TestDataHelper.createPartner();
		INSERT partnerAcc;

		accToInsert = [SELECT Id FROM Account LIMIT 100];
		System.assertEquals(3, accToInsert.size(), 'Account data not created properly!');

		Id accountD = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();

		Account_Discount__c desconto = new Account_Discount__c(
			Account__c = parentAcc.Id,
			EnqixBIDId__c = 12345,
			DiscountSupStartDate__c = system.today(),
			DiscountSupEndDate__c = system.today()+5,
			Product__c = productRec.Id,
			RecordTypeId = accountD,
			Gross_Price__c = 200,
			BID_Price__c = 10,
			Product_Discount__c = 10
		);
		insert desconto;

		Account_Discount__c desconto2 = new Account_Discount__c(
			Account__c = partnerAcc.Id,
			EnqixBIDId__c = 12346,
			DiscountSupStartDate__c = system.today(),
			DiscountSupEndDate__c = system.today()+5,
			Product__c = productRec.Id,
			RecordTypeId = accountD,
			Gross_Price__c = 200,
			BID_Price__c = 10,
			Product_Discount__c = 10
		);
		insert desconto2;
	}

	private static testMethod void unitTest1() {

		List <RecordType> accRecordTypes = [SELECT Id,
											Name
											FROM RecordType
											WHERE SObjectType = 'Account'
											AND (Name = 'Location' OR Name = 'Partner')
										   ];

		Id locationRecordTypeId;
		Id partnerRecordTypeId;

		for(RecordType rec : accRecordTypes) {
			if(rec.Name == 'Location') {
				locationRecordTypeId = rec.Id;
			} else if(rec.Name == 'Partner') {
				partnerRecordTypeId = rec.Id;
			}
		}

		Account location = [SELECT Id, Price_book__c FROM Account WHERE RecordTypeId =: locationRecordTypeId];
		Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1'];
		priceBook2 pb = [SELECT Id FROM priceBook2 WHERE Name = 'Standard Price Book' LIMIT 1];
		PricebookEntry pbEntry = [SELECT Id FROM PricebookEntry WHERE Pricebook2Id = :location.Price_Book__c AND Product2Id = :prod.Id LIMIT 1];
		pbEntry.UnitPrice = 500;
		UPDATE pbEntry;

		system.debug('location --> '+location);

		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');

		Supplier_Product__c sp = new Supplier_Product__c();
		sp.Name = 'test';
		sp.Product__c = prod.id;
		sp.Enqix_UID__c = 'test';
		sp.Enqix_Pk__c = 1;
		sp.Supplier__c = supplier.id;
		insert sp;

		Schedule__c sc = new Schedule__c();
		sc.Collection_Note__c = 'Collection Note';
		sc.Days__c = 'Monday';
		sc.List_Price__c = 500;
		sc.Location__c = location.Id;
		sc.Price_Book__c = pb.Id;
		sc.Product__c = prod.Id;
		sc.Supplier_Product__c = sp.id;
		//sc.Streams__c = 'Cardboard';
		sc.Time__c = '07:45';
		sc.Collection_Quantity__c = 1;
		sc.Supplier__c = supplier.id;

		Test.startTest();
		insert sc;
		Test.stopTest();

		sc = [SELECT Id,
			  List_Price__c,
			  Sale_Price__c
			  FROM Schedule__c
			  WHERE Id =: sc.Id
			 ];

		System.assertEquals(500, sc.List_Price__c,
							'List_Price__c calculation is not working properly!');
		delete sc;
	}
}