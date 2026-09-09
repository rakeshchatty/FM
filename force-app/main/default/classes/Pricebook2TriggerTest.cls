@isTest
public class Pricebook2TriggerTest {
	
   @testSetup
    static void setupTest() {
        
        Container_Type__c ct = new Container_Type__c();
        ct.Name = 'External Bin';
        insert ct;
        
        product2 productRec = TestDataHelper.createProduct('TestProduct', 'Prod1', 'Collection', null, null, ct.Id, '673765');
        INSERT productRec;
        
        priceBook2 pb = new priceBook2();
        pb.Name = 'Test PriceBook ';
        pb.IsActive = true;
        pb.Enqix_Code__c = 1123331;
        pb.Effective_Date__c=System.Today();
        pb.Most_Recent__c = false;
        insert pb;
        
        PricebookEntry priceBookEntry = new  PricebookEntry();
        priceBookEntry.Product2Id = productRec.Id;
        priceBookEntry.Pricebook2Id = Test.getStandardPricebookId();
        priceBookEntry.UnitPrice = 100;
        priceBookEntry.IsActive = True;
        insert priceBookEntry;
        
        Pricebook2 pb2 = new Pricebook2();
        pb2.Id = Test.getStandardPricebookId();
        pb2.IsActive = false;
        pb2.Enqix_Code__c = 1123331;
        pb2.Most_Recent__c = True;
        pb2.Effective_Date__c = system.now();
        Update pb2;
        
        List<Pricebook2> listActivePricebooks = [SELECT id, Enqix_Code__c, Most_Recent__c FROM Pricebook2 WHERE IsActive = true];
 
        Account account = new Account();
        account.Name = 'Xpand IT Account';
        account.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        account.Price_Book__c =  listActivePricebooks[0].Id;
        insert account;
        account.Price_Book__c =  listActivePricebooks[0].Id;
        update account;

        Account locationAcc = new Account();
        locationAcc.Name = 'Location Acc';
        locationAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
        locationAcc.ParentId = account.Id;
        insert locationAcc;
    }
    
    @isTest
    public static void insertAnotherpb() {

        PricebookDateChecker pdc = new PricebookDateChecker();
        pdc.execute(null);

    }
}