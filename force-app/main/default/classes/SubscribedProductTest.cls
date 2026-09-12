@isTest
public class SubscribedProductTest {


    public static testmethod void testNRD(){
        Integer di = 1;
        Integer enqixid = 99992130;
        Id pricebookId = Test.getStandardPricebookId();

        //Inserir accounts
        Account parent = new Account(Name='Sample Monthly Parent Account', InvoiceFrequency__c='Monthly', recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());
        insert parent;
        
        //Insert Child Accounts
        Account acc = TestDataHelper.insertLocation(parent.Id, null);


        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 100, (i+1), 8765+i));
        }
        insert lstProds;


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

        Order Ord2 = new Order(
            AccountId = acc.id,
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

        TestDataHelper.insertSupplier('First Mile Ltd');
        OrderItem o = new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        );
        insert o;

        Subscribed_Products__c spN = new Subscribed_Products__c(
            NextRefreshDate__c = system.today() - 10,
            Product__c = o.Product2Id, 
            Account__c = acc.Id, 
            StartDate__c = Date.newInstance(2016, 11, 01),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Annual',
            quantityOrdered__c = null,
            Enqix_ID__c = string.valueOf(enqixid)
            
            );
        insert spN;

        spN.Enqix_BID_Location_Limit_Period__c = 'Quaterly';
        update spN;

        spN.Enqix_BID_Location_Limit_Period__c = 'Monthly';
        update spN;
    }

	public static testmethod void testAnnual(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS ****************');
		Id parentRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		Account acc;

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
        Account parent = TestDataHelper.insertAccount();
        
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
            Pricebook2Id = pricebookId
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
            Pricebook2Id = pricebookId
        );
        insert ord2;

        TestDataHelper.insertSupplier('First Mile Ltd');
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id,
            NextRefreshDate__c = system.today() - 10,                                                       
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Annual',
            quantityOrdered__c = null,
            Enqix_ID__c = string.valueOf(enqixid));
            o.Quantity += 10;
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;
        update lstOLI;

		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ');
		system.debug('How many Subscribed Products? : ' + newSubs.size());
		for(Subscribed_Products__c p: newSubs){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            p.NextRefreshDate__c = system.today();
            p.quantityOrdered__c = null;
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
            try {
                delete lstOLI.get(0);
            } catch (Exception e) {}
		}
	}

    public static testmethod void testMonthly(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS ****************');
		Account acc;
        Account parent;

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
        Order Ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = acc.id,
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

		TestDataHelper.insertSupplier('First Mile Ltd');
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id,
            NextRefreshDate__c = system.today() - 10,                                                       
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Monthly',
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;
		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ');
		system.debug('How many Subscribed Products? : ' + newSubs.size());
		for(Subscribed_Products__c p: newSubs){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            p.NextRefreshDate__c = system.today();
            p.quantityOrdered__c = null;
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
		}

		Order Ord3 = new Order(
			AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
		);
		insert Ord3;

		lstOLI.add(new OrderItem(
            OrderId = Ord3.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(3).Id,
            UnitPrice = 100
        ));
		//update lstOLI;

        system.debug('CORRE SCH ++++++++++++++++++++++++++++++++++++++++++++');
        SubscribedProductsSch nis = new SubscribedProductsSch();
        nis.execute(null);

        //Run batch TODO - fix , Discount to Apply on Order Item does not exist in production
        Id batchjobId = Database.executeBatch(new updateQuantityOrdered_SubscribedProducts(), 100);



		
	}
    
    public static testmethod void testQuarterly(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS ****************');
		Account acc;
        Account parent;

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
        Order Ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = acc.id,
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

		

		//order Items
		TestDataHelper.insertSupplier('First Mile Ltd');
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id,
            NextRefreshDate__c = system.today() - 10,
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Quarterly',
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;
		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ');
		system.debug('How many Subscribed Products? : ' + newSubs.size());

        Set<Id> spIds = new Set<Id>();
        for(Subscribed_Products__c sp : newSubs){
            spIds.add(sp.Id);
        }

        List<Subscribed_Products__c> sproducts_c = [SELECT Id, quantityOrdered__c, Enqix_BID_Location_Limit_Quantity__c, Quantity_Remaining__c, Quantity_Remaining2__c
        FROM Subscribed_Products__c WHERE Id in :spIds];

		for(Subscribed_Products__c p: sproducts_c){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            Date today = system.today();
            p.NextRefreshDate__c = today;
            p.quantityOrdered__c = null;
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
		}
		
		

        system.debug('CORRE SCH ++++++++++++++++++++++++++++++++++++++++++++');
        SubscribedProductsSch nis = new SubscribedProductsSch();
        nis.execute(null);


		
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

    public static testmethod void testAnnualEndDate(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS ****************');
		Account acc;
        Account parent;

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
        Order Ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = acc.id,
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

		TestDataHelper.insertSupplier('First Mile Ltd');
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id,
            NextRefreshDate__c = system.today() - 10,
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Annual',
            quantityOrdered__c = null,
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;
		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ');
		system.debug('How many Subscribed Products? : ' + newSubs.size());
		for(Subscribed_Products__c p: newSubs){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            p.NextRefreshDate__c = system.today();
            p.quantityOrdered__c = null;
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
		}




		
	}

    public static testmethod void testMonthlyEndDate(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS ****************');
		Account acc;
        Account parent;

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
        Order Ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = acc.id,
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

		TestDataHelper.insertSupplier('First Mile Ltd');
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id, 
            NextRefreshDate__c = system.today() - 10,
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Monthly',
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;
		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ');
		system.debug('How many Subscribed Products? : ' + newSubs.size());
		for(Subscribed_Products__c p: newSubs){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            p.NextRefreshDate__c = system.today();
            p.quantityOrdered__c = null;
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
		}

		Order Ord3 = new Order(
			AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
		);
		insert Ord3;

		lstOLI.add(new OrderItem(
            OrderId = Ord3.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(3).Id,
            UnitPrice = 100
        ));
		//update lstOLI;




		
	}
    
    public static testmethod void testQuarterlyEndDate(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS ****************');
		Account acc;
        Account parent;

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
        Order Ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = acc.id,
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

		

		//order Items
        TestDataHelper.insertSupplier('First Mile Ltd');
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id, 
            NextRefreshDate__c = system.today() - 10,
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Quarterly',
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;
		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ');
		system.debug('How many Subscribed Products? : ' + newSubs.size());
		for(Subscribed_Products__c p: newSubs){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            p.NextRefreshDate__c = system.today();
            p.quantityOrdered__c = null;
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
		}
		
		




		
	}

    public static testmethod void testQuantityOrderedNotNull(){
		system.debug('**************** COMEÇANDO TESTE DAS SUBSCRIBED PRODUCTS NOT NULL ****************');
		Account acc;
        Account parent;

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
        Order Ord1 = new Order(
            AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = acc.id,
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

		TestDataHelper.insertSupplier('First Mile Ltd');
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));
        
        
        
        insert lstOLI;

		
		
		/*
		List<OrderItem> allOrderLines = [SELECT Id, Quantity, Product2Id, Order.AccountId 
            FROM OrderItem WHERE Product2Id = :p.Product__c and Order.AccountId = :p.Account__c]; 
		*/

		List<Subscribed_Products__c> newSubs = new List<Subscribed_Products__c>();
        Integer enqixid = 99992130;
        Integer di = 1;
		for(OrderItem o : lstOLI){
            //Em vez de  Account__c = o.Order.AccountId, pus acc.Id
			Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = o.Product2Id,
            NextRefreshDate__c = system.today() - 10,                                                       
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Annual',
            Enqix_ID__c = string.valueOf(enqixid));
           
            enqixid++;di++;
			system.debug('**************** quero inserir uma nova subscribed product ****************');
			newSubs.add(sp);
		} 
		insert newSubs;

        system.debug(' QUANTOS NEW SUBS EXISTEM-> '+newSubs.size());

        Set<Id> subs = new Set<Id>();
        for(Subscribed_Products__c po : newSubs){
            subs.add(po.Id);
        }
        system.debug('Quantos Ids dos Subs existem? -> ' + subs.size());

        List<Subscribed_Products__c> real = [SELECT Id, quantityOrdered__c, Enqix_BID_Location_Limit_Quantity__c, Quantity_Remaining2__c, Quantity_Remaining__c
        FROM Subscribed_Products__c WHERE Id in :subs];
        
        system.debug('Lista da query tem -> '+real.size() +' subs');
 
		for(Subscribed_Products__c p: real){
			system.debug('# Quantity Ordered: ' + p.quantityOrdered__c + ', Quantity Limit : ' + p.Enqix_BID_Location_Limit_Quantity__c + ', Quantity Remaining1 e 2: ' + p.Quantity_Remaining__c + ' ; ' + p.Quantity_Remaining2__c);
			//TODO It's Quantity_Remaining2__c  because can't change default one to Formula Field Type.
            p.NextRefreshDate__c = system.today();
            system.debug('METE A NEXT REFRESH DATE DATA DE HOJE -> '+p.NextRefreshDate__c);
            update p;
		}
	}
	
    public static testmethod void testCoverageMore(){
		Account acc;
        Account parent;

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
        
        Account partner = TestDataHelper.insertPartner();

        //Insert Child Accounts
        acc = TestDataHelper.insertLocation(parent.Id, partner.Id);
        
        Integer enqixid = 99992130;
        Integer di = 1;
        
        //Insert subscribedProduct
        Subscribed_Products__c sp = new Subscribed_Products__c( Product__c = lstProds.get(1).Id, 
            NextRefreshDate__c = system.today() - 10,                                                         
            Account__c = acc.Id, 
            StartDate__c = system.today().addDays(di),
            EndDate__c = system.today().addDays(di+993),
            Last_Discount_Given__c = Date.newInstance(2017,01,01),
            Enqix_BID_Location_Limit_Quantity__c = 10,
            Enqix_BID_Location_Limit_Period__c = 'Monthly',
            Enqix_ID__c = string.valueOf(enqixid));

        
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
            Enqix_Order_Summary__c = 'aa',
            is_salesforce__c = true
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
            Enqix_Order_Summary__c = null,
            is_salesforce__c = true
        );
        insert ord2;

		TestDataHelper.insertSupplier('First Mile Ltd');
		//order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(1).Id,
            Discount_to_Apply__c = 'Partner',
            Partner_Unit_Price__c = 1
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            Product2Id = lstProds.get(2).Id,
            UnitPrice = 100
        ));        
        insert lstOLI;
        
		//system.debug('Ordered Quantity in the new Subscribed Products inserted: ')

		Order Ord3 = new Order(
			AccountId = acc.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
		);
		insert Ord3;

		lstOLI.add(new OrderItem(
            OrderId = Ord3.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(3).Id,
            UnitPrice = 100
        ));
		//update lstOLI;
        
        system.debug('CORRE SCH ++++++++++++++++++++++++++++++++++++++++++++');
        SubscribedProductsSch nis = new SubscribedProductsSch();
        nis.execute(null);
        Test.startTest();
        SubscribedProductRefreshBatch c = new SubscribedProductRefreshBatch();
        Database.executeBatch(c);
        Test.stopTest();
	
	}
}