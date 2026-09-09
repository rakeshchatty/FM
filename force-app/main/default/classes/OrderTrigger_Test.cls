@isTest
public class OrderTrigger_Test{
    
    @future
    private static void insertCustomSetting(){
      Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
      system.debug('DEBUG========================='+testRecord);
	  insert testRecord;
	}
	@isTest
    public static void UnitTest(){
        TestDataHelper.insertSupplier('First Mile Ltd');
        Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
        User u = new User(Alias = 'newUser', Email='newuser@testorg.com',
         EmailEncodingKey='UTF-8', FirstName='Customer',LastName='Portal', LanguageLocaleKey='en_US',
         LocaleSidKey='en_US', ProfileId = p.Id,
        TimeZoneSidKey='America/Los_Angeles', UserName='nswer123@testorg.com');
        
        System.runAs(u) {
            system.debug('u----->'+u);
        
        Account parentAcc;
    
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

      parentAcc = TestDataHelper.insertAccount();
      Account location = TestDataHelper.insertLocation(parentAcc.Id, null);
        
      Collection_Waypoints__c cw = new Collection_Waypoints__c(Location__c = location.Id);
      insert cw;
      
      Account acc =[SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c FROM Account LIMIT 1];
      
        List<Order> lstOrder = new List<Order>();

        Order Ord1 = new Order(
           AccountId = location.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Collection_Waypoint__c = cw.Id,
            Invoice_Created__c = false
        );
        insert ord1;
        

        Order Ord2 = new Order(
            AccountId = location.Id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord2;
        
        Ord2.EffectiveDate = System.today().addMonths(-(20));
        //update ord2;
		Test.startTest();
        //List<OrderProducts2__c> lstOLI2 = new List<OrderProducts2__c>();
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Discount_to_Apply__c = 'Partner'
        ));
                 
        lstOLI.add(new OrderItem(
            OrderId = ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            UnitPrice = 100
        ));

        insert lstOLI;         
        update lstOLI;
        try {
            delete lstOLI;
        } catch (Exception e) {}
        //delete lstOLI2;
        delete ord2;
		Test.stopTest();
        }
    }
    
     public static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {

        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
		insert proCat;
         
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG; 

        return prod;
    }
}