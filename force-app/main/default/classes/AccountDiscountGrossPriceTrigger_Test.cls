@isTest
public class AccountDiscountGrossPriceTrigger_Test {
    
    @testSetup
    private static void setupTestData() {
        
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        Account partnerAccount = TestDataHelper.createPartner();
        INSERT partnerAccount;
        
        List<Account> accToInsert = [SELECT Id FROM Account LIMIT 100];
        System.assertEquals(3, accToInsert.size(), 'Account data not created properly!');
        
        Product_Category__c productCat = new Product_Category__c();
        productCat.Name = 'Category 1';
        insert productCat;
        
        Product2 productRec = TestDataHelper.insertProduct('Product 1', 'P0001', 'Collection', productCat.Id);
        
        priceBook2 priceBookRec = new priceBook2();
        priceBookRec.Name = 'PriceBook 1';
        priceBookRec.IsActive = true;
        priceBookRec.Effective_Date__c = System.today();
        insert priceBookRec;
        
        PricebookEntry priceBookEntryRec = new  PricebookEntry();
        priceBookEntryRec.Product2Id = productRec.Id;
        priceBookEntryRec.Pricebook2Id = Test.getStandardPricebookId();
        priceBookEntryRec.UnitPrice = 100;
        priceBookEntryRec.UseStandardPrice = false;
        insert priceBookEntryRec;
        
        Account_Discount__c disc = new Account_Discount__c();
        disc.Account__c = partnerAccount.id;
        disc.Product__c = productRec.Id;
        disc.DiscountSupStartDate__c = system.today();
        disc.Product_Discount__c = 5;
        disc.BID_Price__c = 1;
		insert disc;
        
        Order Ord1 = new Order(
           AccountId = locationAccount.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = Test.getStandardPricebookId(),
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0'
        );
        insert ord1;

        TestDataHelper.insertSupplier('First Mile Ltd');
        OrderItem oi = new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            Product2Id = productRec.Id,
            UnitPrice = 100,
            PricebookEntryId = priceBookEntryRec.Id,
            Discount_to_Apply__c = 'Partner'
            );
        insert oi;
    }
    public static testmethod void UnitTest(){
        
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
        
        Account partner = [SELECT Id FROM Account WHERE RecordTypeId =: partnerRecordTypeId];
        Product2 prod = [SELECT Id FROM Product2 WHERE Name = 'Product 1'];
        priceBook2 pb = [SELECT Id FROM priceBook2 WHERE Name = 'PriceBook 1'];
        
        Account_Discount__c disc = new Account_Discount__c();
        disc.Account__c = partner.id;
        disc.Product__c = prod.Id;
        disc.DiscountSupStartDate__c = system.today();
        disc.Product_Discount__c = 5;
		//insert disc;
        
    }
}