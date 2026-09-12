@isTest
public class subscribedProductRefreshDateTest {
    @isTest
    public static void batchTest(){
        List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
    	Account acc;
        Account parent;

        TestDataHelper.insertSupplier('First Mile Ltd');
		//Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 100, (i+1), 8765+i));
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
        
        //Inserir accounts
        parent = new Account(Name='Sample Monthly Parent Account', InvoiceFrequency__c='Monthly', recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());
        insert parent;
        
        //Insert Child Accounts
        acc = TestDataHelper.insertLocation(parent.Id, null);
        
        //Insert Orders for Monthly
        Order ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Enqix_Order_Summary__c = 'aa'
        );
        insert ord1;
        
        Order ord2 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Enqix_Order_Summary__c = null
        );
        insert ord2;
        
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id,
            Discount_to_Apply__c = 'Partner'
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        insert lstOLI;
        
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id, 
            NextRefreshDate__c = system.today(),                                                         
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Normal',
            quantityOrdered__c = 200,
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			newSubs.add(sp);
		} 
		insert newSubs;
        
        system.debug('newSubs.size() ---> '+ newSubs);
        Test.startTest();
        SubscribedProductsSch sch = new SubscribedProductsSch();
        sch.execute(null);
        
        SubscribedProductRefreshBatch batch = new SubscribedProductRefreshBatch();
        Database.executeBatch(batch, 200);
        Test.stopTest();
    }
    
    private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx, Integer enqix) {
        
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        Product_Category__c pcc = new Product_Category__c(Enqix_Id__c = 91,
        Name = 'test_product_category', Product_Category_Key__c = 'a123');
        insert pcc;

        Product_Skin__c pskins = new Product_Skin__c(Enqix_Id__c = 91,
        Name = 'test_product_skin' );
        //insert pskins;
		
        Product2 prod = TestDataHelper.createProduct(prodName, 'test1234', 'Collection', pcc.Id, null, null, string.valueOf(enqix));
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
        prod.Product_Skins__c = pskins.Id;
     
        return prod;
    }
}