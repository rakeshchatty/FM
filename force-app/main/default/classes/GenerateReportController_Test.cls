@isTest
public class GenerateReportController_Test{

    public static testmethod void UnitTestMethod1(){
    
        
        Document doc = new Document(Name='FirstMileLogo', FolderId=UserInfo.getUserId(), DeveloperName='FirstMileLogo');
        insert doc;
    
        ReportPercentEachMonth__c reportPercent = new ReportPercentEachMonth__c(Name = System.now().addMonths(-1).format('MM_yyyy'), Percentage__c = 10);
        insert reportPercent;
    
        List<Product2> lstProds = new List<Product2>();

        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 100, (i+1)));
        }
        insert lstProds;

        Id pricebookId = Test.getStandardPricebookId();
            
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();

        for (Integer i=0; i<11; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;

          Account parentAcc = new Account(Name='Sample Parent Account', RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());
          insert parentAcc;
      
      
        Account acc = new Account();
        acc.Name = 'Test Account';
        acc.Report_Type__c = 'Group Report';
        acc.Report_Date__c = date.today();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
        acc.ParentId= parentAcc.id;
        acc.Price_Book__c = pricebookId;
        acc.Enqix_Dead_Live__c = 'Live';
        insert acc;
        
        
        Account acc2 = new Account();
        acc2.Name = 'Test Account2';
        acc2.Report_Type__c = 'CO2 Report';
        acc2.Report_Date__c = date.today();
        acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
        acc2.ParentId= parentAcc.id;
        insert acc2;
        
        List<Order> lstOrder = new List<Order>();

        for (Integer i=0; i<11; i++) {

            lstOrder.add(new Order(
                AccountId = acc.Id,
                EffectiveDate = System.today().addMonths(-(i)),
                Delivery_Date__c = System.today().addMonths(-(i)),
                Status = 'Confirmed',
                AD_KG__c = 100,
                Recycled_KG__c = 100,
                WTE_KG__c = 100,
                Tonnes_CO2_Saved__c = 100,
                Pricebook2Id = pricebookId
            ));
        }
      
        insert lstOrder;

        List<OrderItem> lstOLI = new List<OrderItem>();
        for (Integer i=0; i<11; i++) {
            lstOLI.add(new OrderItem(
                OrderId = lstOrder.get(i).Id,
                Quantity = 1,
                PriceBookEntryId = lstStandardPrice.get(i).Id,
                UnitPrice = 100
            ));

        }

        insert lstOLI;
        
        ApexPages.StandardController sc = new ApexPages.StandardController(acc);
        GenerateReportController cls = new GenerateReportController(sc);
        cls.acc.Linked_Group__c = acc.Id;
        cls.GenerateReport();
        cls.getDownloadTypes();
        
        cls.selectedDownloadType = 'Excel';
        cls.DownloadReport();
        
        cls.selectedDownloadType = 'PDF';
        cls.DownloadReport();
        
        ApexPages.StandardController sc2 = new ApexPages.StandardController(acc2);
        GenerateReportController cls2 = new GenerateReportController(sc2);
        cls2.acc.Linked_Group__c = acc2.Id;
        cls2.GenerateReport();
        cls2.getDownloadTypes();
        
        cls2.selectedDownloadType = 'Excel';
        cls2.DownloadReport();
        
        cls2.selectedDownloadType = 'PDF';
        cls2.DownloadReport();
    }

    
    private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {

        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
		
        Product2 prod = TestDataHelper.createProduct(prodName, 'test123', 'Collection');
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
       
        return prod;
    }
}