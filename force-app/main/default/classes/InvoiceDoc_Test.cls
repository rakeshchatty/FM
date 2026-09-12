@isTest
public with sharing class InvoiceDoc_Test {

	@isTest
	public static void cMonthly(){
		system.debug('Começando testes monthly');
        Account am1, am2;
        Account parentMonthly;
        Account partner;
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        TestDataHelper.insertSupplier('First Mile Ltd');

        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
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
        parentMonthly = new Account(Name='Sample Monthly Parent Account', InvoiceFrequency__c='Monthly', recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());
        insert parentMonthly;
        
        partner = TestDatahelper.createPartner();
        partner.InvoiceFrequency__c='Monthly';
        insert partner;
        
        //Insert Child Accounts
        am1 = TestDataHelper.createLocation(parentMonthly.Id, partner.Id);
        am1.Name='Sample Monthly Child Account 1';
        am1.IsInvoiceFrequencyOverride__c = true;
        am1.InvoiceFrequency__c='Monthly';
        insert am1; 

        am1 = [select Id, Name, ParentId, InvoiceFrequency__c from Account where Id = :am1.Id limit 1];
        //am2 = [select Id, Name, ParentId, InvoiceFrequency__c from Account where Id = :am2.Id limit 1];
        system.debug('Parent Account 1: '+am1.ParentId);
        //system.debug('Parent Account 2: '+am2.ParentId);
        //Insert Orders for Monthly
        Order Ord1 = new Order(
            AccountId = am1.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            is_Salesforce__c = true
        );
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = am1.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            is_Salesforce__c = true
        );
        insert ord2;
        
        Ord2.EffectiveDate = System.today().addMonths(-(20));
        update ord2;
        
        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 10,
            PriceBookEntryId = lstStandardPrice.get(0).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(0).Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 10,
            PriceBookEntryId = lstStandardPrice.get(0).Id,
            UnitPrice = 100,
            Product2Id = lstProds.get(0).Id
        ));
        insert lstOLI;
        //This should insert 2 invoice headers, for each Order
        ord1 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c, Total_Amount_Including_Partner__c from Order where Id = :Ord1.Id limit 1];
        ord2 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c, Total_Amount_Including_Partner__c from Order where Id = :Ord2.Id limit 1];
        system.debug('Order 1:'+ord1);
        system.debug('Order 2:'+ord2);
        List<OrderItem> lstOLIO1 = [Select Id from OrderItem where OrderId = :Ord1.Id];
        List<OrderItem> lstOLIO2 =  [Select Id from OrderItem where OrderId = :Ord2.Id];
        system.debug('Order Items on Ord1: ' + lstOLIO1.size() + '    |    Order Items on Ord1: ' + lstOLIO2.size());

        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        orderIds.add(Ord2.Id);
        
        Subscribed_Products__c sp1 = new Subscribed_Products__c(
        	Account__c = am1.Id,
            Product__c = lstProds.get(0).Id,
            quantityOrdered__c = 50,
            Quantity_Remaining__c = 500,
            Enqix_ID__c = '1234555689'
        );
        insert sp1;
        
        List<Invoice_Header__c> invoicesList = new List<Invoice_Header__c>();
        Invoice_Header__c invoice1 = new Invoice_Header__c(Name='JRPG Inv1 Test Cov',
                                                         	InvoiceFrequency__c = 'Monthly',
                                                         	Account__c = parentMonthly.Id,
                                                         	Location__c = am1.Id,
                                                            Status__c = 'Draft',
                                                            Salesforce__c = true,
                                                          	DueDate__c = system.today());
        Invoice_Header__c invoice2 = new Invoice_Header__c(Name='JRPG Inv2 Test Cov',
                                                         	InvoiceFrequency__c = 'Monthly',
                                                         	Account__c = parentMonthly.Id,
                                                         	Location__c = am1.Id,
                                                            Salesforce__c = true,
                                                          	DueDate__c = system.today());
        invoicesList.add(invoice1);
        invoicesList.add(invoice2);
        insert invoicesList;
        
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, DueDate__c, Status__c, AmountInclVAT__c, InvoiceFrequency__c
                                            FROM Invoice_Header__c 
                                            WHERE OrderLookUp__c in :orderIds];
        system.debug('Quantos headers? #'+headers.size());

        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];
        //system.debug('Quantos invoice lines? #' + lines.size());
        //system.assert(headers.size() == 1);
        //system.assert(lines.size() == 2);

        system.debug('CORRE SCH ++++++++++++++++++++++++++++++++++++++++++++');
        Date today = system.today();
        //Change due date para testar apenas se o sch funciona
        /*for(Invoice_Header__c header : headers){
            header.DueDate__c = today;
        }*/
        //upsert(headers);
        system.debug('Quantos headers? #'+headers.size());

        for(Invoice_Header__c ih : headers){
            system.debug('IH ID'+ih.Id+'      |      Inv Method: '+ ih.InvoiceFrequency__c);
            InvoiceDocRedirectExtension idre = new InvoiceDocRedirectExtension(ih);
			PageReference p = idre.redirect();
            
        }
	}
	@isTest
	public static void criarHeaders_e_testarPerOrder() {
		Account an1, an2;
        Account parentPerOrder, parentPerOrder2;
        Account partner;
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        //Suppliers
        Suppliers__c testSupplier = TestDataHelper.insertSupplier('First Mile Ltd');
        
        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
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
        
        
        //Insert Parent Accounts
        parentPerOrder = new Account(Name='Sample Per Order Parent Account', InvoiceFrequency__c='Per Order', recordtypeid=Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());
        insert parentPerOrder;

        partner = TestDatahelper.createPartner();
        partner.InvoiceFrequency__c='Monthly';
        insert partner;
        
        //Insert Child Accounts
        an1 = TestDataHelper.createLocation(parentPerOrder.Id, partner.Id);
        an1.Name='Sample Per Order Child Account 12';
        insert an1; 

        
        //Insert Orders for Per Order
        Order Ord1 = new Order(
            AccountId = an1.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Invoice_Created__c = false,
            is_Salesforce__c = true,
            Partner_Total_Amount__c = 10
        );
        System.debug('A gravar ord1');
        insert ord1;
        
        Order Ord2 = new Order(
            AccountId = an1.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Invoice_Created__c = false,
            is_Salesforce__c = true,
            Partner_Total_Amount__c = 10
        );
        System.debug('A gravar ord2');
        insert ord2;
       
        Ord2.EffectiveDate = System.today().addMonths(-(20));
        update ord2;
        
        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100,
            Product2Id = lstProds[0].Id
        ));
        
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            UnitPrice = 100,
            Product2Id = lstProds[1].Id
        ));
        
        
        
        insert lstOLI;
        
        //This should insert 2 invoice headers, for each Order
        Ord2.Status = 'Delivered';
        Ord1.Status = 'Delivered';
        Ord1.Created_Later__c = true;
        Ord2.Created_Later__c = true;
        upsert Ord1; upsert Ord2;
        
        ord1 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c, Total_Amount_Including_Partner__c from Order where Id = :Ord1.Id limit 1];
        ord2 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c, Total_Amount_Including_Partner__c from Order where Id = :Ord2.Id limit 1];
        system.debug('Order 1:'+ord1);
        system.debug('Order 2:'+ord2);
        
        Subscribed_Products__c sp = new Subscribed_Products__c(
        	Account__c = an1.Id,
            Product__c = lstProds.get(0).Id,
            quantityOrdered__c = 50,
            Quantity_Remaining__c = 500
        );
        upsert sp;
        
        List<Subscribed_Products__c> allsubs = [SELECT Id, Account__c, Product__c, quantityOrdered__c
                                                FROM Subscribed_Products__c];
        system.debug('allsubs.size--- '+allsubs.size());
        
        List<Invoice_Header__c> invoicesList = new List<Invoice_Header__c>();
        Invoice_Header__c invoice1 = new Invoice_Header__c(Name='JRPG Inv1 Test Cov',
                                                         	InvoiceFrequency__c = 'Monthly',
                                                         	Account__c = parentPerOrder.Id,
                                                         	Location__c = an1.Id,
                                                            Status__c = 'Draft',
                                                            Salesforce__c = true,
                                                          	DueDate__c = system.today());
        Invoice_Header__c invoice2 = new Invoice_Header__c(Name='JRPG Inv2 Test Cov',
                                                         	InvoiceFrequency__c = 'Monthly',
                                                         	Account__c = parentPerOrder.Id,
                                                         	Location__c = an1.Id,
                                                            Salesforce__c = true,
                                                          	DueDate__c = system.today());
        invoicesList.add(invoice1);
        invoicesList.add(invoice2);
        insert invoicesList;
        
        List<Invoice_Header__c> newHeaders1 = [SELECT Id, OrderLookUp__c  FROM Invoice_Header__c where OrderLookUp__c = :Ord1.Id];
        List<Invoice_Header__c> newHeaders2 = [SELECT Id, OrderLookUp__c  FROM Invoice_Header__c where OrderLookUp__c = :Ord2.Id];
        System.debug('newHeaders1.size() = ' + newHeaders1.size());
        System.debug('newHeaders2.size() = ' + newHeaders2.size());
        //System.assert( newHeaders1.size()>0 );
        //System.assert( newHeaders2.size()>0 );
        
        //Check how many Invoice Lines each Header has
        Set<Id> headers1 = new Set<Id>();
        for(Invoice_Header__c h1 : newHeaders1){
            headers1.add(h1.Id);
        }
        Set<Id> headers2 = new Set<Id>();
        for(Invoice_Header__c h2 : newHeaders2){
            headers2.add(h2.Id);
        }
        List<Invoice_Line__c> lines1 = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers1];
        List<Invoice_Line__c> lines2 = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers2];
        System.debug('#Invoice Lines on Header #1 = '+  lines1.size());
        System.debug('#Invoice Lines on Header #2 = '+  lines2.size());

		List<PageReference> pagess = new List<PageReference>();
		
		for(Invoice_Header__c hhh : newHeaders1){
			
			InvoiceDocRedirectExtension idre = new InvoiceDocRedirectExtension(hhh);
			PageReference p = idre.redirect();
			
		}
	}
    
	private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {
        
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
		insert proCat;
        
        Product_Skin__c skin = new Product_Skin__c(
            Name = 'SECURE DESTRUCTION'
        );
        insert skin;
		
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
        prod.Product_Skins__c = skin.Id;
        prod.Delivery_Category__c = 'Delivery';

        return prod;
    }
}