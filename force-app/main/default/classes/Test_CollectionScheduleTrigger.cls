@isTest
public class Test_CollectionScheduleTrigger {
    /*
    @testSetup
    private static void setupTestData() {
        
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
        
        List<Account> accToInsert = new List<Account>();
        
        Account locationAcc = new Account();
        locationAcc.Name = 'Location Acc';
        locationAcc.RecordTypeId = locationRecordTypeId;
        accToInsert.add(locationAcc);
        
        Account partnerAcc = new Account();
        partnerAcc.Name = 'Partner Acc';
        partnerAcc.RecordTypeId = partnerRecordTypeId;
        accToInsert.add(partnerAcc);
        
        insert accToInsert;
        locationAcc.Partnership__c = partnerAcc.Id;
        update locationAcc;
        
        accToInsert = [SELECT Id FROM Account LIMIT 100];
        System.assertEquals(2, accToInsert.size(), 'Account data not created properly!');
        
        Product_Category__c pc = new Product_Category__c();
        pc.Name = 'test';
        pc.Enqix_Id__c = 1;
        pc.Product_Category_Key__c = 'test';
        insert pc;
        
        product2 productRec = new Product2();
        productRec.Name =  'Product 1';
        productrec.ProductCode = '123';
        productRec.Product_Category__c = pc.id;
        productRec.Product_Type__c = 'Collection';
        productRec.isActive = true;
        insert productRec;
        
        priceBook2 priceBookRec = new priceBook2();
        priceBookRec.Name = 'PriceBook 1';
        priceBookRec.IsActive = true;
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
        
        Account_Discount__c disc1 = new Account_Discount__c();
        disc1.Account__c = locationAcc.id;
        disc1.Product__c = productRec.Id;
        disc1.Product_Discount__c = 3;
        disc1.DiscountSupStartDate__c = system.today();
        
        Account_Discount__c disc2 = new Account_Discount__c();
        disc2.Account__c = locationAcc.id;
        disc2.Product__c = productRec.Id;
        disc2.Product_Discount__c = 5;
        disc2.DiscountSupStartDate__c = system.today();
        
        Account_Discount__c disc3 = new Account_Discount__c();
        disc3.Account__c = locationAcc.id;
        disc3.Product__c = productRec.Id;
        disc3.Product_Discount__c = 50;
        disc3.DiscountSupStartDate__c = system.today();
        
        Test.startTest();
        insert new List<Account_Discount__c>{disc1, disc2, disc3};
        Test.stopTest();
    }
    */
    
    /*
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
        
        Account location = [SELECT Id FROM Account WHERE RecordTypeId =: locationRecordTypeId];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1'];
        priceBook2 pb = [SELECT Id FROM priceBook2 WHERE Name = 'PriceBook 1'];
        

        Suppliers__c s = new Suppliers__c();
        s.Name = 'test';
        s.Enqix_ID__c = 23;
        s.Phone_Number__c = '123423';
        insert s;
        
        Supplier_Product__c sp = new Supplier_Product__c();
        sp.Name = 'test';
        sp.Product__c = prod.id;
        sp.Enqix_UID__c = 'test';
        sp.Enqix_Pk__c = 1;
        sp.Supplier__c = s.id;
        insert sp;
                
        Schedule__c sc = new Schedule__c();
        sc.Collection_Note__c = 'Collection Note';
        sc.Days__c = 'Monday';
        sc.Location__c = location.Id;
        //sc.Price_Book__c = pb.Id;
        sc.Product__c = prod.Id;
        sc.Supplier_Product__c = sp.id;
        sc.Streams__c = 'Cardboard';
        sc.Time__c = '07:45';
        sc.Collection_Quantity__c = 1;
        sc.Supplier__c = s.id;
        
        
            insert sc;
        
        sc = [SELECT Id, 
                List_Price__c, 
                Sale_Price__c 
                FROM Schedule__c 
                WHERE Id =: sc.Id
             ];
        //System.assertEquals(sc.List_Price__c - 50, sc.Sale_Price__c, 'Sale Price calculation is not working properly!');
    }
    */
    
    public TestMethod Static void Test1()
    {
        Test.startTest(); 
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
        
        Account parentAcc = TestDataHelper.insertAccount();
        Account partnerAcc = TestDataHelper.insertPartner();
        Account locationAcc = TestDataHelper.insertLocation(parentAcc.Id, partnerAcc.Id);
        
        System.assertEquals(3, [SELECT Id FROM Account].size(), 'Account data not created properly!');
        
        Product_Category__c pc = new Product_Category__c();
        pc.Name = 'test';
        pc.Enqix_Id__c = 1;
        pc.Product_Category_Key__c = 'test';
        insert pc;
        
        product2 productRec = TestDataHelper.insertProduct('Product 1 (P)', '123', 'Collection', pc.Id);
        
        priceBook2 priceBookRec = new priceBook2();
        priceBookRec.Name = 'PriceBook 1';
        priceBookRec.IsActive = true;
        priceBookRec.Effective_Date__c = System.now();
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
        
        
        Account location = [SELECT Id FROM Account WHERE RecordTypeId =: locationRecordTypeId];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1 (P)'];
        priceBook2 pb = [SELECT Id FROM priceBook2 WHERE Name = 'PriceBook 1'];
        
        
        Suppliers__c s = new Suppliers__c();
        s.Name = 'test';
        s.Enqix_ID__c = 23;
        s.Phone_Number__c = '123423';
        insert s;
        
        Supplier_Product__c sp = new Supplier_Product__c();
        sp.Name = 'test';
        sp.Product__c = prod.id;
        sp.Enqix_UID__c = 'test';
        sp.Enqix_Pk__c = 1;
        sp.Supplier__c = s.id;
        insert sp;
                
        Schedule__c sc = new Schedule__c();
        sc.Collection_Note__c = 'Collection Note';
        sc.Days__c = 'Monday';
        sc.Location__c = location.Id;
        //sc.Price_Book__c = pb.Id;
        sc.Product__c = prod.Id;
        sc.Supplier_Product__c = sp.id;
        sc.Streams__c = 'Cardboard';
        sc.Time__c = '07:45';
        sc.Collection_Quantity__c = 1;
        sc.Supplier__c = s.id;
        
        insert sc;
        
        Update sc;
        system.debug('sc::'+sc);
        Test.stopTest();
    }
}