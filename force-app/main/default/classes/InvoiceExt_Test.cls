@isTest
public with sharing class InvoiceExt_Test {

	@testSetup
	static void setup() {
        TestDataHelper.insertDefaultLegalEntity('Test Entity');
    }

    @future
    private static void insertCustomSetting(){
      Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
      system.debug('DEBUG========================='+testRecord);
	  insert testRecord;
	}

	@isTest
	public static void InvoiceExtensionTest() {
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        TestDataHelper.insertSupplier('First Mile Ltd');
		system.debug('Começando testes monthly');
        Account am1, am2;
        Account parentMonthly;
        
        //Products
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
        
        //Inserir accounts
        parentMonthly = new Account(
                                    Name='Sample Monthly Parent Account',
                                    InvoiceFrequency__c='Per order',
        							recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId());
        insert parentMonthly;

        //Insert Child Accounts
        am1 = new Account(Name='Sample Monthly Child Account 1',
                          ParentId=parentMonthly.id,
                          Enqix_Location_ID__c='123456789',
                          recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId(),
                          Enqix_Dead_Live__c = 'Live',
                          Price_Book__c = pricebookId);
        insert am1; 
        
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
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100
        ));
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            UnitPrice = 100
        ));
        insert lstOLI;
        
        //This should insert 2 invoice headers, for each Order
        Ord1.Status = 'Delivered';
        Ord2.Status = 'Delivered';
        update Ord1; 
        update Ord2;
        ord1 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c from Order where Id = :Ord1.Id limit 1];
        ord2 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c from Order where Id = :Ord2.Id limit 1];
        system.debug('Order 1:'+ord1);
        system.debug('Order 2:'+ord2);
        
        List<OrderItem> lstOLIO1 = [Select Id from OrderItem where OrderId = :Ord1.Id];
        List<OrderItem> lstOLIO2 =  [Select Id from OrderItem where OrderId = :Ord2.Id];
        system.debug('Order Items on Ord1: ' + lstOLIO1.size() + '    |    Order Items on Ord2: ' + lstOLIO2.size());

        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        orderIds.add(Ord2.Id);
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, DueDate__c, Status__c, AmountInclVAT__c, InvoiceFrequency__c
                                            FROM Invoice_Header__c 
                                            WHERE Account__c = :parentMonthly.Id];

        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];
        system.debug('Quantos headers? #'+headers.size());
        system.debug('Quantos invoice lines? #' + lines.size());

        Date today = system.today();
        //Change due date para testar apenas se o sch funciona
        /*for(Invoice_Header__c header : headers){
            header.DueDate__c = today;
        }*/
        //upsert(headers);
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
        Invoice_Line__c invoiceLine1 = new Invoice_Line__c(Name='JRPG Inv1 Line Test Cov',
                                                         	Invoice_HeaderId__c = invoice1.Id,
                                                         	Salesforce__c = true,
                                                         	Order__c = Ord1.Id,
                                                          	Location_Id__c=am1.Id,
                                                          	Amount__c=1);
        Invoice_Line__c invoiceLine2 = new Invoice_Line__c(Name='JRPG Inv2 Line Test Cov',
                                                         	Invoice_HeaderId__c = invoice2.Id,
                                                         	Salesforce__c = true,
                                                         	Order__c = Ord2.Id,
                                                          	Location_Id__c=am1.Id,
                                                          	Amount__c=1);
        insert invoiceLine1;
        insert invoiceLine2;
        for(Invoice_Header__c ih : invoicesList){
            system.debug('IH ID'+ih.Id+'      |      Inv Method: '+ ih.InvoiceFrequency__c);
            ApexPages.StandardController sc = new ApexPages.StandardController(ih);
            InvoiceExtension idre = new InvoiceExtension(sc);
			//PageReference p = idre.redirect();
            
        }

	}
	
    @isTest
	public static void InvoiceExtensionPerOrderTest() {
        TestDataHelper.insertSupplier('First Mile Ltd');
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
		system.debug('Começando testes Per Order');
        
        //Products
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
        
        Account parentAccount = TestDataHelper.createAccount();
        INSERT  parentAccount;
        //Inserir accounts
        Account acc = new Account (
                                    Name='Sample Per Order Parent Account1',
                                    RecordtypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId(),
                                    parentId = parentAccount.Id,
                                    Enqix_Dead_Live__c = 'Live',
                                    Price_Book__c = pricebookId);
        insert acc;
                
        //Insert Orders for Per Order
        Order Ord1 = new Order(
            AccountId = acc.id,
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
            AccountId = acc.id,
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
        system.debug('Ver invoice method das novas orders:  que vem do parent Id = '+acc.Id);
        system.debug('Ver invoice method das novas orders:  que vem do parent Id = '+acc.Id);
        
        Ord2.EffectiveDate = System.today().addMonths(-(20));
        update ord2;
        
        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100
        ));
        lstOLI.add(new OrderItem(
            OrderId = Ord2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            UnitPrice = 100
        ));
        insert lstOLI;
        
        //This should insert 2 invoice headers, for each Order
        Ord1.Status = 'Delivered';
        Ord2.Status = 'Delivered';
        update Ord1; 
        update Ord2;
        ord1 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c from Order where Id = :Ord1.Id limit 1];
        ord2 = [select Id, Name, Status, AccountId, Account.ParentId, Created_Later__c, Invoice_Created__c, is_Salesforce__c from Order where Id = :Ord2.Id limit 1];
        system.debug('Order 1:'+ord1);
        system.debug('Order 2:'+ord2);
        
        List<OrderItem> lstOLIO1 = [Select Id from OrderItem where OrderId = :Ord1.Id];
        List<OrderItem> lstOLIO2 =  [Select Id from OrderItem where OrderId = :Ord2.Id];
        system.debug('Order Items on Ord1: ' + lstOLIO1.size() + '    |    Order Items on Ord2: ' + lstOLIO2.size());

        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        orderIds.add(Ord2.Id);
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, DueDate__c, Status__c, AmountInclVAT__c, InvoiceFrequency__c
                                            FROM Invoice_Header__c 
                                            WHERE Account__c = :acc.Id];

        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];

        Date today = system.today();

		List<Invoice_Header__c> invoicesList = new List<Invoice_Header__c>();
        Invoice_Header__c invoice1 = new Invoice_Header__c(Name='JRPG Inv1 Test Cov',
                                                         	InvoiceFrequency__c = 'Per Order',
                                                         	Account__c = parentAccount.Id,
                                                         	Location__c = acc.Id,
                                                          	DueDate__c = today);
        Invoice_Header__c invoice2 = new Invoice_Header__c(Name='JRPG Inv2 Test Cov',
                                                         	InvoiceFrequency__c = 'Per Order',
                                                         	Account__c = parentAccount.Id,
                                                         	Location__c = acc.Id,
                                                          	DueDate__c = today);
        invoicesList.add(invoice1);
        invoicesList.add(invoice2);
        insert invoicesList;
        Invoice_Line__c invoiceLine1 = new Invoice_Line__c(Name='JRPG Inv1 Line Test Cov',
                                                         	Invoice_HeaderId__c = invoice1.Id,
                                                         	Salesforce__c = true,
                                                         	Order__c = Ord1.Id,
                                                          	Location_Id__c=acc.Id,
                                                          	Amount__c=1);
        Invoice_Line__c invoiceLine2 = new Invoice_Line__c(Name='JRPG Inv2 Line Test Cov',
                                                         	Invoice_HeaderId__c = invoice2.Id,
                                                         	Salesforce__c = true,
                                                         	Order__c = Ord2.Id,
                                                          	Location_Id__c=acc.Id,
                                                          	Amount__c=1);
        insert invoiceLine1;
        insert invoiceLine2;
        for(Invoice_Header__c ih : invoicesList){

            ApexPages.StandardController sc = new ApexPages.StandardController(ih);
            InvoiceExtensionPerOrder idre = new InvoiceExtensionPerOrder(sc);
			//PageReference p = idre.redirect();
            
        }

	}
	private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {
        
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
		insert proCat;
        
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;

        return prod;
    }
}