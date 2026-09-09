@isTest
private class AccountDiscountTriggerTest {

	@isTest
	static void validateAccountDiscountInsert() {

		/*Product_Category__c productCat = new Product_Category__c();
        productCat.Name = 'Cardboard';
        insert productCat;
        
        Product_Skin__c productSkin = new Product_Skin__c();
        productSkin.Name = 'Collection Skin';
        insert productSkin;*/

		Product2 productRec = TestDataHelper.insertProduct('Product 1','P0001', 'Delivery');
        
        priceBook2 priceBookRec = new priceBook2();
        priceBookRec.Name = 'My Price Book ';
        priceBookRec.IsActive = true;
        pricebookRec.Effective_Date__c=System.Today();
		pricebookRec.Most_Recent__c = true;
        insert priceBookRec;
        priceBookRec = [SELECT Id, Name, IsActive, Effective_Date__c FROM Pricebook2 LIMIT 1];
        
        PricebookEntry priceBookEntryStandardRec = new  PricebookEntry();
        priceBookEntryStandardRec.Product2Id = productRec.Id;
        priceBookEntryStandardRec.Pricebook2Id = Test.getStandardPricebookId();
        priceBookEntryStandardRec.UnitPrice = 100;
		priceBookEntryStandardRec.IsActive = True;
        insert priceBookEntryStandardRec;
        
        Pricebook2 pb2 = new Pricebook2();
        pb2.Id = Test.getStandardPricebookId();
        pb2.IsActive = false;
        pb2.Enqix_Code__c = 1123331;
        pb2.Most_Recent__c = True;
        pb2.Effective_Date__c = system.now();
        Update pb2;

		Account account = new Account ();
        account.Name = 'Test Account';
		Id pricebookId = priceBookRec.Id;
		System.debug('Account pricebook Id: ' + priceBookRec.Id);
		System.debug('Account pricebook Id: ' + pricebookId);
        account.Price_Book__c =  pricebookId;
		account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		system.debug('Saving account');
        insert account;
        account = [SELECT id, Name, RecordTypeId, Price_Book__c FROM Account WHERE Name = 'Test Account' LIMIT 1];
        account.Price_Book__c =  pricebookId;
        update account;
        account = [SELECT id, Name, RecordTypeId, Price_Book__c FROM Account WHERE Name = 'Test Account' LIMIT 1];

		System.debug('Account: ' + account);
		Account_Discount__c baseAccountDiscount = new Account_Discount__c();
		baseAccountDiscount.RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
		baseAccountDiscount.account__c = account.Id;
		baseAccountDiscount.product__c = productRec.id;
		baseAccountDiscount.DiscountSupStartDate__c= (system.today()-3);
		baseAccountDiscount.DiscountSupEndDate__c = (system.today()+3);
        insert baseAccountDiscount;

		list<Account_Discount__c> lad = new list<Account_Discount__c> ();
		
		Account_Discount__c successfullBeforeAccountDiscount = new Account_Discount__c();
		successfullBeforeAccountDiscount.RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
		successfullBeforeAccountDiscount.account__c = account.Id;
		successfullBeforeAccountDiscount.product__c = productRec.id;
		successfullBeforeAccountDiscount.DiscountSupStartDate__c= (system.today()-7);
		successfullBeforeAccountDiscount.DiscountSupEndDate__c = (system.today()-4);
		lad.add(successfullBeforeAccountDiscount);
        
		Account_Discount__c successfullAfterAccountDiscount = new Account_Discount__c();
		successfullAfterAccountDiscount.RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
		successfullAfterAccountDiscount.account__c = account.Id;
		successfullAfterAccountDiscount.product__c = productRec.id;
		successfullAfterAccountDiscount.DiscountSupStartDate__c= (system.today()+4);
		successfullAfterAccountDiscount.DiscountSupEndDate__c = (system.today()+7);
		lad.add(successfullAfterAccountDiscount);

		Account_Discount__c overlapingStartAccountDiscount = new Account_Discount__c();
		overlapingStartAccountDiscount.RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
		overlapingStartAccountDiscount.account__c = account.Id;
		overlapingStartAccountDiscount.product__c = productRec.id;
		overlapingStartAccountDiscount.DiscountSupStartDate__c= (system.today()-2);
		overlapingStartAccountDiscount.DiscountSupEndDate__c = (system.today()+4);
		lad.add(overlapingStartAccountDiscount);

		Account_Discount__c overlapingEndAccountDiscount = new Account_Discount__c();
		overlapingEndAccountDiscount.RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
		overlapingEndAccountDiscount.account__c = account.Id;
		overlapingEndAccountDiscount.product__c = productRec.id;
		overlapingEndAccountDiscount.DiscountSupStartDate__c= (system.today()-4);
		overlapingEndAccountDiscount.DiscountSupEndDate__c = (system.today()+2);
		lad.add(overlapingEndAccountDiscount);

		Account_Discount__c nullEndAccountDiscount = new Account_Discount__c();
		nullEndAccountDiscount.RecordTypeId = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
		nullEndAccountDiscount.account__c = account.Id;
		nullEndAccountDiscount.product__c = productRec.id;
		nullEndAccountDiscount.DiscountSupStartDate__c= (system.today()-4);
		lad.add(nullEndAccountDiscount);

        Database.SaveResult[] AccntDiscResultSet = Database.insert(lad,false);
        system.assertEquals(AccntDiscResultSet[0].isSuccess(), true);
        system.assertEquals(AccntDiscResultSet[1].isSuccess(), true);
        system.assertEquals(AccntDiscResultSet[2].isSuccess(), false);
        system.assertEquals(AccntDiscResultSet[3].isSuccess(), false);
        system.assertEquals(AccntDiscResultSet[4].isSuccess(), false);
	}
	
}