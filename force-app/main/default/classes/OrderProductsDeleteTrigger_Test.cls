@isTest
public with sharing class OrderProductsDeleteTrigger_Test {
    
    @future
    private static void insertCustomSetting(){
      Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
	  insert testRecord;
	}
	@isTest
	public static void unitTest(){
		List<Product2> lstProds = new List<Product2>();

		for (Integer i=0; i<2; i++) {
			lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
		}
		insert lstProds;

		Id pricebookId = Test.getStandardPricebookId();
		List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();

		for (Integer i=0; i<2; i++) {
			lstStandardPrice.add(new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = lstProds.get(i).Id,
				UnitPrice = 10,
				IsActive = true
			));
		}
		insert lstStandardPrice;
        Id parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Id partnerRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
        Id locationRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
        
        Pricebook2 pricebook = new Pricebook2(Name = 'Standard Price List 1', Enqix_Id__c = '1', isActive = true, Most_Recent__c = true, Effective_Date__c = system.today());
		insert pricebook;
        
        Account accParent;
		accParent = new Account(Name='Sample Parent Account', RecordTypeId = parentRecordTypeId, Price_Book__c = pricebook.Id);
		insert accParent;
        
        system.Debug('accParent ---- '+accParent);
        
        Account accPartner;
		accPartner = new Account(Name='Sample Partner Account', RecordTypeId = partnerRecordTypeId);
		insert accPartner;

		Account acc;
		acc = new Account(Name='Sample child Account', Partnership__c = accPartner.id, ParentId = accParent.Id, RecordTypeId = locationRecordTypeId, Enqix_Dead_Live__c = 'Live', Price_Book__c = pricebookId);
		insert acc;
        
        Id accountD = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('AccountDiscount').getRecordTypeId();
        
        Account_Discount__c desconto = new Account_Discount__c(
			Account__c = accParent.Id,
            EnqixBIDId__c = 12345,
			DiscountSupStartDate__c = system.today(),
			DiscountSupEndDate__c = system.today()+5,
			Product__c = lstProds.get(0).Id,
			RecordTypeId = accountD,
			Gross_Price__c = 200,
			BID_Price__c = 10,
			Product_Discount__c = 10
		);
		insert desconto;
        
      /*  Account_Discount__c desconto2 = new Account_Discount__c(
			Account__c = accPartner.Id,
            EnqixBIDId__c = 12346,
			DiscountSupStartDate__c = system.today(),
			DiscountSupEndDate__c = system.today()+5,
			Product__c = lstProds.get(0).Id,
			RecordTypeId = accountD,
			Gross_Price__c = 200,
			BID_Price__c = 10,
			Product_Discount__c = 10
		);
		insert desconto2; */
        
        system.debug('acc ----- '+ acc);

		/*Order2__c order2 = new Order2__c(Account__c = acc.Id, 
		Orderer_Name__c = 'Test');
		order2.Order_Placed_Date__c = system.today();
		order2.Order_Type__c = 'Regular';
		order2.Price_Book__c = pricebookId;
		//order2.Delivery_Status__c = 'Awaiting Allocation'; //Delete
		insert order2;*/
        
        Order order = new order();
        order.EffectiveDate = date.today();
        order.Status = 'Draft';
        order.AccountId = acc.Id;
        order.Pricebook2Id = pricebookId;
        order.Delivery_Status__c = 'Awaiting Allocation';
        order.Type = 'Regular';
        insert order;
		
       /* system.debug('Order.Account__r.ParentId ---- ' + order.Account.ParentId);
		OrderProducts2__c pro2 = new OrderProducts2__c(Product__c = lstProds.get(0).Id,
		Order2__c = order2.Id
		);
		
		insert pro2;
		upsert order2; */
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
        OrderItem op3 = new OrderItem();
        op3.Quantity = 1;
        op3.ListPrice__c = 1;
        op3.Description__c = '123';
        op3.Product2Id = lstProds.get(0).Id; //prod2.Id
        op3.Price_Book__c = pricebookId;
        op3.OrderId = order.Id;
		Test.startTest();
        insert op3;
		Test.stopTest();
        //op3.Discount_to_Apply__c = 'Account';

        
        Supplier_Product__c suppProd1 = new Supplier_Product__c(
             Name = 'testSuppProd1',
             Supplier__c = supplier.Id,
             Product__c = lstProds.get(0).Id,
             Start_Date__c = system.today() - 5,
             End_Date__c = system.today() + 5,
             Enqix_UID__c = '1233321'
         );   
         Database.SaveResult set1 = Database.insert(suppProd1, false); 
        
		  
		/*Order2__c order23 = new Order2__c(Account__c = acc.Id, Orderer_Name__c = 'Test');
		order23.Order_Placed_Date__c = system.today();
		order23.Order_Type__c = 'Regular';
		order23.Price_Book__c = pricebookId;
		//order23.Delivery_Status__c = 'Allocated'; //Not to delete
		insert order23;*/
        
         Order order2 = new order();
        order2.EffectiveDate = date.today();
        order2.Status = 'Draft';
        order2.AccountId = acc.Id;
        order2.Pricebook2Id = pricebookId;
        order2.Type = 'Regular';
        insert order2;
        
        OrderItem op4 = new OrderItem();
        op4.Quantity = 1;
        op4.ListPrice__c = 1;
        op4.Description__c = '123';
        op4.Product2Id = lstProds.get(0).Id; //prod2.Id
        op4.Price_Book__c = pricebookId;
        op4.OrderId = order2.Id;
        insert op4;
        try {
            delete op4;
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains(Label.NoPermissionToDeleteOrderItem), Label.NoPermissionToDeleteOrderItem);
        }
        //op3.Discount_to_Apply__c = 'Account';
        
        //system.debug('Order.Account__r.ParentId ---- ' + order2.Account.ParentId);

		/*OrderProducts2__c pro23 = new OrderProducts2__c(Order2__c = order23.Id, 
		Product__c = lstProds.get(0).Id);
        insert pro23;         
        delete pro23;*/
	 
        upsert order2;
	}


	private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {

        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
		Product_Category__c proCat = new Product_Category__c(Name = 'Test');
		insert proCat;
 		
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;      

        return prod;
    }

}