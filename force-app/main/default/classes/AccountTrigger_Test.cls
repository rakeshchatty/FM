@isTest
class AccountTrigger_Test{
    
    @isTest
    public static void UnitTestMethod1(){
        
        test.startTest();
        List<Product2> lstProds = new List<Product2>();

        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProduct('Prod-' + (i + 1), 5, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();

        for (Integer i=0; i<5; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 102,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        Id RecordTypeIdAccount = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Id RecordTypeIdPartner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Id RecordTypeIdLocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();

        Id RecordTypeIdAccountDisc = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
        
        Account acc1 = new Account();
        acc1.Name = 'Parent Account';
        acc1.RecordTypeId = RecordTypeIdAccount;
        insert acc1;
  
        Account partnerAcc = new Account();
        partnerAcc.Name = 'Partner Account';
        partnerAcc.RecordTypeId = RecordTypeIdPartner;
        partnerAcc.Price_Book__c = pricebookId;
        partnerAcc.Enqix_Classification__c = 'BID';
        insert partnerAcc;
        
        Test.stopTest();
        
        List <Account> accList = new List <Account>();
        
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.RecordTypeId = RecordTypeIdLocation;
        acc.ParentId = acc1.Id;
        acc.Enqix_Location_ID__c  = 'ABC123';
        acc.Price_Book__c = Test.getStandardPricebookId();
        acc.Enqix_Dead_Live__c = 'Live';
        acc.Partnership__c = partnerAcc.Id;
        acc.Enqix_Classification__c = 'BID';        
        accList.add(acc);
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account2';
        acc2.RecordTypeId = RecordTypeIdLocation;
        acc2.ParentId = acc1.Id;
        acc2.Enqix_Location_ID__c  = 'ABC123';
        acc2.Price_Book__c = Test.getStandardPricebookId();
        acc2.Enqix_Dead_Live__c = 'Live';
        acc2.Partnership__c = partnerAcc.Id;
        acc2.Enqix_Classification__c = 'BID';        
        accList.add(acc2);
        
        insert accList;
        
        acc.Partnership__c = null;
        
        update acc;
        
        List<Account_Discount__c> accDisc = new List <Account_Discount__c>();
        
        Account_Discount__c disc = new Account_Discount__c();
        disc.Account__c = partnerAcc.id;
        disc.Product__c = lstProds.get(0).Id;
        disc.DiscountSupStartDate__c = system.today();
        disc.BID_allocation_product__c = True;
        disc.RecordTypeId = RecordTypeIdAccountDisc;
        disc.DiscountSupEndDate__c = system.today()+100;
        disc.Gross_Price__c = 50;        
        accDisc.add(disc);
        
        insert accDisc;
        
        AccountTriggerHelper.createSubscribedProducts(accList, accDisc);
        
        Account acc5 =[SELECT Id, RecordTypeId, Price_Book__c FROM  Account LIMIT 1];
         
        opportunity opp = new opportunity();
        opp.Name = 'Test Opp';
        opp.CloseDate = date.today().AddDays(-60);
        opp.StageName = '5 Collections Started';
        opp.AccountId = acc1.Id;
        opp.Services__c = 'Secure Shredding';
        insert opp;
        
        Order ord = new Order();
        ord.AccountId = acc.Id;
        ord.Status = 'Invoiced';
        ord.OK_or_Cancelled__c = 'Cancelled';
        ord.EffectiveDate = system.today();
        ord.Delivery_Date__c = Date.newInstance(2018, 06, 29);
        insert ord;
        
        acc.Enqix_Dead_Live__c ='Dead';
        acc.Enqix_ReasonMarkedDead__c = 'Giveaway Never Ordered';
        update acc;
    }
    
    private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {
        String rpGroup = (Math.mod(idx, 2) == 0) ? 'Cardboard' : 'Food Recycling';
        
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Collection');
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
       
        return prod;
    }
}