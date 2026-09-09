@isTest
public class OrderTriggerHelper_Test {

     @testSetup static void setup() {
         List<Product_Skin__c> prodSkins = new List<Product_Skin__c>();
        // Create Product Skins
        Product_Skin__c secdestrPS = new Product_Skin__c();
        secdestrPS.Name = 'Sec Destr';
        prodSkins.add(secdestrPS);

        Product_Skin__c weee = new Product_Skin__c(); 
        weee.Name = 'WEEE';
        prodSkins.add(weee);
        insert prodSkins;

        TestDataHelper.insertSupplier('First Mile Ltd');
    }
    
    //@future
    private static void insertCustomSetting(){
      Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
      system.debug('DEBUG========================='+testRecord);
    }

    public static testmethod void TestPartnershipMonthlyWheelie(){
        Invoicing.BOOL_TEST_FUTURE = True;
        insertCustomSetting();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        Account parentMonthly;
       
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price List 1', Enqix_Id__c = '1', isActive=true, Most_Recent__c = true, Effective_Date__c = system.today());
        insert pricebook;
        Id pricebookId = Test.getStandardPricebookId();
        
        
        Id partnerdiscount = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();
        system.debug('partnerdiscount: ' + partnerdiscount);
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account teste_Partner = new Account(
            Name='Sample Monthly Parent Account', 
            RecordTypeId = partner,
            Price_Book__c = pricebookId,
            Enqix_Classification__c = 'BID',
            Enqix_ID__c = '131231'
            );
        insert teste_Partner;
        Account selecionadaAccount = [SELECT Id, RecordTypeId, RecordType.DeveloperName, Price_Book__c FROM Account WHERE Id = :teste_Partner.Id];
        system.debug('***RecordType: ' + selecionadaAccount.RecordTypeId + ' ' + selecionadaAccount.RecordType.DeveloperName);

        Product2 teste_Product = createTestProduct('Prod-' + 1, 10, 1);
        insert teste_Product;

        Account_Discount__c discount = new Account_Discount__c(           
            Account__c = selecionadaAccount.Id,
            Product__c = teste_Product.Id,
            BID_Rebate__c = 5,
            RecordTypeId = partnerdiscount,
            DiscountSupEndDate__c = system.today().addDays(100),
            DiscountSupStartDate__c = system.today(),
            Gross_Price__c = 200,
            Product_Discount__c = 10
        );
        
        insert discount;

        Account_Discount__c descontoSelecionado = [SELECT Id, Account__c, RecordTypeId, RecordType.DeveloperName, Account__r.Price_Book__c
        from Account_Discount__c where Id =:discount.Id];
        system.debug('***RecordType: ' + descontoSelecionado.RecordTypeId + ' ' + descontoSelecionado.RecordType.DeveloperName);
        system.debug('***Record Type: ' + partnerdiscount);
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;

        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();

        lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = teste_Product.Id,
                UnitPrice = 100,
                IsActive = true
            )

        );
        insert lstStandardPrice;
        
        system.debug('Number of queries: '  +Limits.getQueries());

        // Monthly
        parentMonthly = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parentMonthly.Id, teste_Partner.Id);
       
        //Insert Orders for Monthly
        List<Order> ordersToinsert = new List<Order>();
        Order Ord1 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Partner_Total_Amount__c = 200,
            Pricebook2Id = pricebookId
        );
        ordersToinsert.add(Ord1);       
        insert ordersToinsert;
        
        List<OrderItem> lstOLI2 = new List<OrderItem>();
        //More Order Items on the Order 3
        lstOLI2.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 2,
            Product2Id = teste_Product.Id,
            PriceBookEntryId = lstStandardPrice.get(0).Id,
            UnitPrice = 200,
            Discount_to_Apply__c = 'Partner'
        ));
        Test.startTest();
        insert lstOLI2;
        
        system.debug('Number of queries: '  +Limits.getQueries());
   
        system.debug('******* Discount:' + descontoSelecionado);
        Order ordemSelecionada = [SELECT Id, Account.Partnership__c FROM Order where Id = :Ord1.Id];
        system.debug('******* Order:' + ordemSelecionada);
        system.debug('******* Conta do Desconto' + descontoSelecionado.Account__c + 
        ' RecordType: ' + descontoSelecionado.RecordTypeId + ' ' + descontoSelecionado.RecordType.DeveloperName);
        system.debug('******** Partnership da ordem:' + ordemSelecionada.Account.Partnership__c);
        
        List<Account_Discount__c> discounts = [SELECT Id, Product__c, Account__c, RecordTypeId, BID_Price__c, BID_Rebate__c, RecordType.DeveloperName
         from Account_Discount__c where RecordType.DeveloperName = 'PartnerDiscount'
         ];
         system.debug(discounts);

        for (OrderItem o : [SELECT Id, Partner_Unit_Price__c FROM OrderItem]) {
            system.debug(o);
        }

        Order o = [SELECT Id, Partner_Total_Amount__c FROM Order WHERE Id = :Ord1.Id];
        system.debug(o);

        //************************************* 2 - Activate Trigger
        
        Ord1.Status = 'Delivered';
        update Ord1;
        system.debug('Number of queries: '  +Limits.getQueries());

        

        //************************************* 3 - Debugs
        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        
        Invoice_Header__c invoice = new Invoice_Header__c (
            Name = 'Teste',
            OrderLookUp__c = ord1.Id,
            CreatedDate__c = system.today(),
            Account__c = parentMonthly.Id,
            DueDate__c = system.today(),
            AmountExclVAT__c = 50,
            VAT__c = 50,
            AmountInclVAT__c = 100,
            Status__c = 'Draft',
            InvoiceFrequency__c = 'Per Order',
            Salesforce__c = true
        );
        insert invoice;
        
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, CreatedDate__c, Account__c, Account__r.Name, Location__c, Location__r.Name, Name, DueDate__c, AmountExclVAT__c, VAT__c, AmountInclVAT__c, Status__c, InvoiceFrequency__c, OrderIds__c  
                                            FROM Invoice_Header__c 
                                            WHERE OrderLookUp__c in :orderIds AND Salesforce__c = true AND Status__c = 'Draft'];
        system.debug('Quantos headers? #'+headers.size());
        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];

        Date today = system.today();
        //Change due date para testar apenas se o sch funciona
        //for(Invoice_Header__c header : headers){
           // header.DueDate__c = today;
       // }
        //upsert(headers);

        for(Invoice_Header__c ih : headers){
            if(ih.DueDate__c.day() == today.day() && today.month() == ih.DueDate__c.month() && today.year() == ih.DueDate__c.year()){
                system.debug('--------------------> It is today equal!! ');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }else{
                system.debug('------------------------------->Not today!');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }
            
        }

        system.debug('Add more lines to the header please');

        
        system.debug('Number of queries: '  +Limits.getQueries());

        Test.stopTest();
        orderIds.add(Ord1.Id);

        headers = [SELECT Id, OrderLookUp__c, CreatedDate__c, Account__c, Account__r.Name, Location__c, Name, DueDate__c, AmountExclVAT__c, VAT__c, AmountInclVAT__c, Status__c, InvoiceFrequency__c, OrderIds__c  
                                            FROM Invoice_Header__c 
                                            WHERE OrderLookUp__c in :orderIds];
        lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];

        for(Invoice_Header__c ih : headers){
            if(ih.DueDate__c.day() == today.day() && today.month() == ih.DueDate__c.month() && today.year() == ih.DueDate__c.year()){
                system.debug('--------------------> It is today equal!! ');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }else{
                system.debug('------------------------------->Not today!');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }
            
        }                
    }
    
    public static testmethod void TestPartnershipMonthly(){
        
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        Account parentMonthly;
       
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price List 1', Enqix_Id__c = '1', isActive=true, Most_Recent__c = true, Effective_Date__c = system.today());
        insert pricebook;
        Id pricebookId = Test.getStandardPricebookId();
        
        
        Id partnerdiscount = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();
        system.debug('partnerdiscount: ' + partnerdiscount);
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account teste_Partner = new Account(
            Name='Sample Monthly Parent Account', 
            InvoiceFrequency__c='Monthly',
            RecordTypeId = partner,
            Price_Book__c = pricebookId,
            Enqix_Classification__c = 'BID',
            Enqix_ID__c = '131231'
            );
        insert teste_Partner;
        
        Account selecionadaAccount = [SELECT Id, RecordTypeId, RecordType.DeveloperName, Price_Book__c FROM Account WHERE Id = :teste_Partner.Id];
        system.debug('***RecordType: ' + selecionadaAccount.RecordTypeId + ' ' + selecionadaAccount.RecordType.DeveloperName);

        Product2 teste_Product = createTestProduct('Prod-' + 1, 10, 1);
        insert teste_Product;

        Account_Discount__c discount = new Account_Discount__c(           
            Account__c = selecionadaAccount.Id,
            Product__c = teste_Product.Id,
            BID_Rebate__c = 5,
            RecordTypeId = partnerdiscount,
            DiscountSupEndDate__c = system.today().addDays(100),
            DiscountSupStartDate__c = system.today(),
            Gross_Price__c = 200,
            Product_Discount__c = 10
        );
        
        insert discount;

        Account_Discount__c descontoSelecionado = [SELECT Id, Account__c, RecordTypeId, RecordType.DeveloperName, Account__r.Price_Book__c
        from Account_Discount__c where Id =:discount.Id];
        system.debug('***RecordType: ' + descontoSelecionado.RecordTypeId + ' ' + descontoSelecionado.RecordType.DeveloperName);
        system.debug('***Record Type: ' + partnerdiscount);
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;

        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();

        lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = teste_Product.Id,
                UnitPrice = 100,
                IsActive = true
            )

        );
        insert lstStandardPrice;
        
        system.debug('Number of queries: '  +Limits.getQueries());

        // Monthly
        parentMonthly = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parentMonthly.Id, teste_Partner.Id);
        
        //Insert Orders for Monthly
        List<Order> ordersToinsert = new List<Order>();
        Order Ord1 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Partner_Total_Amount__c = 200,
            Pricebook2Id = pricebookId
        );
        ordersToinsert.add(Ord1);       
        
        Order Ord2 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Partner_Total_Amount__c = 200,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        ordersToinsert.add(Ord2);
        insert ordersToinsert;

        List<OrderItem> lstOLI2 = new List<OrderItem>();
        //More Order Items on the Order 3
        lstOLI2.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 2,
            Product2Id = teste_Product.Id,
            PriceBookEntryId = lstStandardPrice.get(0).Id,
            UnitPrice = 200
        ));

        insert lstOLI2;
        system.debug('Number of queries: '  +Limits.getQueries());
   
        system.debug('******* Discount:' + descontoSelecionado);
        Order ordemSelecionada = [SELECT Id, Account.Partnership__c FROM Order where Id = :Ord1.Id];
        system.debug('******* Order:' + ordemSelecionada);
        system.debug('******* Conta do Desconto' + descontoSelecionado.Account__c + 
        ' RecordType: ' + descontoSelecionado.RecordTypeId + ' ' + descontoSelecionado.RecordType.DeveloperName);
        system.debug('******** Partnership da ordem:' + ordemSelecionada.Account.Partnership__c);
        

        //order Items
        /*List<OrderItem> lstOLI = new List<OrderItem>();

        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            Product2Id = teste_Product.Id,
            //TODO normally when creating an Order item, does it come with the Product2Id filled or just the pricebookentryid ? 
            PriceBookEntryId = lstStandardPrice.get(0).Id,
            UnitPrice = 100
        ));
        

        insert lstOLI;
        system.debug('Number of queries: '  +Limits.getQueries());*/
        
        List<Account_Discount__c> discounts = [SELECT Id, Product__c, Account__c, RecordTypeId, BID_Price__c, BID_Rebate__c, RecordType.DeveloperName
         from Account_Discount__c where RecordType.DeveloperName = 'PartnerDiscount'
         ];
         system.debug(discounts);

        for (OrderItem o : [SELECT Id, Partner_Unit_Price__c FROM OrderItem]) {
            system.debug(o);
        }

        Order o = [SELECT Id, Partner_Total_Amount__c FROM Order WHERE Id = :Ord1.Id];
        system.debug(o);

        //************************************* 2 - Activate Trigger
        
        system.debug('Number of queries: '  +Limits.getQueries());

        

        //************************************* 3 - Debugs
        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        orderIds.add(Ord2.Id);
        
        Invoice_Header__c invoice = new Invoice_Header__c (
            Name = 'Teste',
            OrderLookUp__c = ord1.Id,
            CreatedDate__c = system.today(),
            Account__c = parentMonthly.Id,
            DueDate__c = system.today(),
            AmountExclVAT__c = 50,
            VAT__c = 50,
            AmountInclVAT__c = 100,
            InvoiceFrequency__c = 'Per Order',
            Status__c = 'Draft',
            Salesforce__c = true
        );
        insert invoice;
        
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, CreatedDate__c, Account__c, Account__r.Name, Location__c, Location__r.Name, Name, DueDate__c, AmountExclVAT__c, VAT__c, AmountInclVAT__c, Status__c, InvoiceFrequency__c, OrderIds__c  
                                            FROM Invoice_Header__c 
                                            WHERE OrderLookUp__c in :orderIds AND Salesforce__c = true AND Status__c = 'Draft'];
        system.debug('Quantos headers? #'+headers.size());
        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];

        Date today = system.today();
        //Change due date para testar apenas se o sch funciona
        //for(Invoice_Header__c header : headers){
           // header.DueDate__c = today;
       // }
        //upsert(headers);

        for(Invoice_Header__c ih : headers){
            if(ih.DueDate__c.day() == today.day() && today.month() == ih.DueDate__c.month() && today.year() == ih.DueDate__c.year()){
                system.debug('--------------------> It is today equal!! ');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }else{
                system.debug('------------------------------->Not today!');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }
            
        }

        system.debug('Add more lines to the header please');


        Ord1.Status = 'Delivered';
        update Ord1;
        orderIds.add(Ord1.Id);

        headers = [SELECT Id, OrderLookUp__c, CreatedDate__c, Account__c, Account__r.Name, Location__c, Name, DueDate__c, AmountExclVAT__c, VAT__c, AmountInclVAT__c, Status__c, InvoiceFrequency__c, OrderIds__c  
                                            FROM Invoice_Header__c 
                                            WHERE OrderLookUp__c in :orderIds];
        lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];

        for(Invoice_Header__c ih : headers){
            if(ih.DueDate__c.day() == today.day() && today.month() == ih.DueDate__c.month() && today.year() == ih.DueDate__c.year()){
                system.debug('--------------------> It is today equal!! ');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }else{
                system.debug('------------------------------->Not today!');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }
            
        }
        Test.startTest();
        Order Ord4= new Order(
            AccountId = location.Id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 1111,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert Ord4;

        List<OrderItem> lstOLI3 = new List<OrderItem>();

        lstOLI3.add(new OrderItem(
            OrderId = Ord4.Id,
            Quantity = 1,
            Product2Id = teste_Product.Id,
            //TODO normally when creating an Order item, does it come with the Product2Id filled or just the pricebookentryid ? 
            PriceBookEntryId = lstStandardPrice.get(0).Id,
            UnitPrice = 100
        ));
        insert lstOLI3;
        
        Order ord = [select Id from order where Recycled_KG__c = 1111 limit 1];
        ord.Status = 'Delivered';
        update ord;
        Test.stopTest();
 
        insertCustomSetting();
        //OrderTriggerHelper.entry(ordersToinsert);
        //OrderTriggerHelper.createInvoice(orderIds);
       
}

    public static testmethod void TestPartnershipPerOrder(){
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        Account parentMonthly;
        
        Pricebook2 pricebook = new Pricebook2(Name='Standard Price List 1', Enqix_Id__c = '1', isActive=true, Most_Recent__c = true, Effective_Date__c = system.today());
        insert pricebook;
        Id pricebookId2 = pricebook.Id;
        Id pricebookId = Test.getStandardPricebookId();
               
        Id partnerdiscount = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();
        system.debug('partnerdiscount: ' + partnerdiscount);
        Id partner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();

        Account teste_Partner = new Account(
            Name='Sample Per Order Parent Account', 
            InvoiceFrequency__c = 'Monthly',
            RecordTypeId = partner,
            Price_Book__c = pricebookId2,
            Enqix_Classification__c = 'BID',
            Enqix_ID__c = '131231'
            );
        insert teste_Partner;

        Account selecionadaAccount = [SELECT Id, RecordTypeId, RecordType.DeveloperName FROM Account WHERE Id = :teste_Partner.Id];
        system.debug('***RecordType: ' + selecionadaAccount.RecordTypeId + ' ' + selecionadaAccount.RecordType.DeveloperName);
        

        Product2 teste_Product = createTestProduct('Prod-' + 1, 10, 1);
        insert teste_Product;

        Account_Discount__c discount = new Account_Discount__c(
            //Name = 'Teste_Desconto_Partner',
            
            Account__c = teste_Partner.Id,
            Product__c = teste_Product.Id,
            BID_Price__c = 10,
            //RecordType.DeveloperName = 'PartnerDiscount',
            RecordTypeId = partnerdiscount,
            DiscountSupEndDate__c = system.today().addDays(100),
            DiscountSupStartDate__c = system.today(),
            Gross_Price__c = 200,
            Product_Discount__c = 10
            


        );
        insert discount;

        Account_Discount__c descontoSelecionado = [SELECT Id, Account__c, RecordTypeId, RecordType.DeveloperName
        from Account_Discount__c];

        system.debug('***RecordType: ' + descontoSelecionado.RecordTypeId + ' ' + descontoSelecionado.RecordType.DeveloperName);
        system.debug('***Record Type: ' + partnerdiscount);

        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;

        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        for (Integer i=0; i<3; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }

        lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = teste_Product.Id,
                UnitPrice = 100,
                IsActive = true
            )

        );
        insert lstStandardPrice;

        
        
        parentMonthly = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parentMonthly.Id, null);

        //Insert Orders for Monthly 
        List<Order> orderstoins = new List<Order>();
        Order Ord1 = new Order(
            AccountId = location.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        orderstoins.add(Ord1);

        
        
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
        orderstoins.add(Ord2);

        Order Ord3 = new Order(
            AccountId = location.Id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Delivered',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        orderstoins.add(Ord3);
        
        insert orderstoins;
        system.debug('Number of queries: '  +Limits.getQueries());

        system.debug('******* Discount:' + descontoSelecionado);
        Order ordemSelecionada = [SELECT Id, Account.Partnership__c FROM Order where Id = :Ord1.Id];
        system.debug('******* Order:' + ordemSelecionada);
        system.debug('******* Conta do Desconto' + descontoSelecionado.Account__c + 
        ' RecordType: ' + descontoSelecionado.RecordTypeId + ' ' + descontoSelecionado.RecordType.DeveloperName);
        system.debug('******** Partnership da ordem:' + ordemSelecionada.Account.Partnership__c);
        

        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();

        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 1,
            Product2Id = teste_Product.Id,
            //TODO normally when creating an Order item, does it come with the Product2Id filled or just the pricebookentryid ? 
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100
        ));
        lstOLI.add(new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 2,
            Product2Id = teste_Product.Id,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 200
        ));

        insert lstOLI;
        system.debug('Number of queries: '  +Limits.getQueries());

        Order o = [SELECT Id, Partner_Total_Amount__c FROM Order WHERE Id = :Ord1.Id];
        system.debug(o);

        //************************************* 2 - Activate Trigger
        Ord1.Status = 'Delivered';
        Ord2.Status = 'Delivered';
        Ord3.Status = 'Delivered';
        update Ord1;
        update Ord2;
        update Ord3;
        system.debug('Number of queries: '  +Limits.getQueries());

        //************************************* 3 - Debugs
        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, CreatedDate__c, Account__c, Account__r.Name, Location__c, Name, DueDate__c, AmountExclVAT__c, VAT__c, AmountInclVAT__c, Status__c, InvoiceFrequency__c, OrderIds__c  
                                            FROM Invoice_Header__c 
                                            WHERE OrderLookUp__c in :orderIds];
        system.debug('Quantos headers? #'+headers.size());
        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];
        system.debug('Quantos invoice lines? #' + lines.size());
        system.debug('O que tem nos Headers?' + headers);
        system.debug('O que tem nos lines?' + lines);

        for(Invoice_Header__c thisHeaderWhat : headers){
            system.debug(thisHeaderWhat.DueDate__c);
        }

        Date today = system.today();
        //Change due date para testar apenas se o sch funciona
        //for(Invoice_Header__c header : headers){
          //  header.DueDate__c = today;
        //}
        //upsert(headers);

        for(Invoice_Header__c ih : headers){
            if(ih.DueDate__c.day() == today.day() && today.month() == ih.DueDate__c.month() && today.year() == ih.DueDate__c.year()){
                system.debug('--------------------> It is today equal!! ');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }else{
                system.debug('------------------------------->Not today!');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
            }
            
        }

    }
    
    public static testmethod void UnitTestMonthly(){
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        system.debug('Começando testes monthly');
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        
        for (Integer i=0; i<3; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        //Inserir accounts
        Account parentMonthly = TestDataHelper.insertAccount();
        Account location =  TestDataHelper.insertLocation(parentMonthly.Id, null);
        
        //Insert Child Accounts
        Account am1 =[SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c FROM  Account LIMIT 1];
        Account am2 =[SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c FROM  Account LIMIT 1];
        //am1 = new Account(Name='Sample Monthly Child Account 1', ParentId=parentMonthly.id, InvoiceFrequency__c='Monthly');
        //am2 = new Account(Name='Sample Monthly Child Account 2', ParentId=parentMonthly.id, InvoiceFrequency__c='Monthly');
        
        //Insert Orders for Monthly
        List<Order> orders = new List<Order>();
        Order Ord1 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        orders.add(Ord1);
        
        Order Ord2 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true,
            Type = 'Invoicing',
            PO_Number__c = 'WheelieBinOrder0'
        );
        orders.add(Ord2);

        Order ord3 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(2)),
            Delivery_Date__c = System.today().addMonths(-(2)),
            Status = 'Delivered',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        orders.add(Ord3);
        insert orders;
        
        Ord2.EffectiveDate = System.today().addMonths(-(20));
        update Ord2;
        
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
        Ord2.Status = 'Delivered';
        Ord1.Status = 'Delivered';
        upsert Ord1; 
        upsert Ord2;
        
        //BEGIN: More test coverage for the continue monthly
        //Insert Orders for Monthly - Insert a new one for the Account AM1 so it then gets created and then change the status to Delivered to update the Invoice. 
        Order orderM2 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        insert orderM2;

        List<OrderItem> ois = new List<OrderItem>();
        ois.add(new OrderItem(
            OrderId = orderM2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 100
        ));
        ois.add(new OrderItem(
            OrderId = orderM2.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(2).Id,
            UnitPrice = 100
        ));
        insert ois;


        orderM2.status = 'Delivered';
        update orderM2;

        // END


        Set<Id> orderIds = new Set<Id>();
        orderIds.add(Ord1.Id);
        orderIds.add(Ord2.Id);
        List<Invoice_Header__c> headers = [SELECT Id, OrderLookUp__c, DueDate__c, Status__c, AmountInclVAT__c
                                        FROM Invoice_Header__c 
                                          WHERE OrderLookUp__c in :orderIds];
        system.debug('Quantos headers? #'+headers.size());
        List<Invoice_Line__c> lines = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers];
        system.debug('Quantos invoice lines? #' + lines.size());
        //system.assert(headers.size() == 1);
        //system.assert(lines.size() == 2);

        Date today = system.today();
        //Change due date para testar apenas se o sch funciona
        /*for(Invoice_Header__c header : headers){
            header.DueDate__c = today;
        }*/
        //upsert(headers);

        for(Invoice_Header__c ih : headers){
            if(ih.DueDate__c.day() == today.day() && today.month() == ih.DueDate__c.month() && today.year() == ih.DueDate__c.year()){
                system.debug('--------------------> It is today equal!! ');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
                //system.assert(ih.Status__c == 'Invoiced');
                //system.assert(ih.AmountInclVAT__c != null );
            }else{
                system.debug('------------------------------->Not today!');
                system.debug('-----> ' + ih.DueDate__c + '<------' + ih.Status__c);
                //system.assert(ih.Status__c == 'Draft');
                //system.assert(ih.AmountInclVAT__c != null );
            }
            
        }
    }
     
    public static testmethod void UnitTestPerOrder(){
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        system.debug('Começando testes Per Order');
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        
        for (Integer i=0; i<3; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        
        //Insert Parent Accounts
        Account parentPerOrder = TestDataHelper.createAccount();
        parentPerOrder.InvoiceFrequency__c = 'Per Order';
        INSERT parentPerOrder;
        Account location =  TestDataHelper.insertLocation(parentPerOrder.Id, null);
        
        //Insert Child Accounts
        Account an1 =[SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c FROM  Account WHERE InvoiceFrequency__c = 'Per Order' LIMIT 1];
        
        //Insert Orders for Per Order
        Order ord1 = new Order(
            AccountId = location.id,
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
        
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        //User u = [Select Id from User Where Alias='Cport'];
        
        //System.runAs(u) {
            
            Order ord2 = new Order(
                AccountId = location.id,
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
            system.debug('Ver invoice method das novas orders:  que vem do parent Id = '+parentPerorder.InvoiceFrequency__c);

            Order ord3 = new Order(
                AccountId = location.id,
                EffectiveDate = System.today().addMonths(-(2)),
                Delivery_Date__c = System.today().addMonths(-(2)),
                Status = 'Confirmed',
                AD_KG__c = 100,
                Recycled_KG__c = 100,
                WTE_KG__c = 100,
                Tonnes_CO2_Saved__c = 100,
                Pricebook2Id = pricebookId
            );
            insert ord3;
            
            ord3.AD_KG__c = 200;
            update ord3;
            
            List<Order> o = [select InsertedAsDelivered__c, createddate From Order];
            system.debug(o);
            
            //order Items
            List<OrderItem> lstOLI = new List<OrderItem>();
            lstOLI.add(new OrderItem(
                OrderId = ord1.Id,
                Quantity = 1,
                PriceBookEntryId = lstStandardPrice.get(1).Id,
                UnitPrice = 100
            ));
            
            lstOLI.add(new OrderItem(
                OrderId = ord2.Id,
                Quantity = 1,
                PriceBookEntryId = lstStandardPrice.get(2).Id,
                UnitPrice = 100
            ));
            
            lstOLI.add(new OrderItem(
                OrderId = ord3.Id,
                Quantity = 1,
                PriceBookEntryId = lstStandardPrice.get(2).Id,
                UnitPrice = 100
            ));
            
            insert lstOLI;

            //This should insert 2 invoice headers, for each Order
            ord2.Status = 'Delivered';
            ord1.Status = 'Delivered';
            upsert ord1; 
            upsert ord2;

            List<Invoice_Header__c> newHeaders1 = [SELECT Id, OrderLookUp__c, Status__c  FROM Invoice_Header__c where OrderLookUp__c = :Ord1.Id];
            List<Invoice_Header__c> newHeaders2 = [SELECT Id, OrderLookUp__c , Status__c FROM Invoice_Header__c where OrderLookUp__c = :Ord2.Id];
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
            List<Invoice_Line__c> lines1 = [Select Id, Invoice_HeaderId__r.Status__c FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers1];
            List<Invoice_Line__c> lines2 = [Select Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c in :headers2];
            System.debug('#Invoice Lines on Header #1 = '+  lines1.size());
            System.debug('#Invoice Lines on Header #2 = '+  lines2.size());
            
            system.debug('AQUI ------------------------------------------------------- AQUI -------------');
            if(newHeaders1.size() > 0){
                Invoice_Header__c head9 = newHeaders1.get(0);
                system.debug(head9.Status__c);
            }
            
            for(Invoice_Line__c linhax : lines1){
                system.debug(linhax.Invoice_HeaderId__r.Status__c);
            }
        
        test.startTest();
        	List <OrderItem> ots = [Select Id from orderItem where OrderId =: ord3.Id];
        	system.debug('OrderItem to delete --> '+ots.size());
            try {
                delete ots;
            } catch (Exception e) {}
        	
        test.stopTest();
        //} 
    }
    
    private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) { 
        
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
        insert proCat;

        Product_Skin__c skin = new Product_Skin__c(
            Name = 'WEEE test'
        );
        insert skin;

        Product2 prod = new Product2(
            Name = prodName, 
            Report_Groupings__c = rpGroup,
            Recycle_KG__c = recycleKG,
            IsActive = true,
            Product_Category__c = proCat.Id,
            ProductCode = '123',
            Product_Type__c = 'Delivery',
            UnitCost__c = 10,
            Product_Skins__c = skin.Id,
            Delivery_Category__c = 'Delivery',
            Nl_accode__c = '4001'
        );        
        
        return prod;
    }

    public static testmethod void UnitTestGetLastWorkingDay(){
        system.debug('TESTE LAST WORKING DAY');
        OrderTriggerHelper helper = new OrderTriggerHelper();
        Date dt = Date.newInstance(2018,07,19);

        Date lastWorkingDay = Duration.toMonthEnd(dt);
        system.debug('TESTE LAST WORKING DAY ' + lastWorkingDay.day()+' == 31');
        //system.assert( lastWorkingDay.day() == 31);


        Date setembro = Date.newInstance(2018, 09, 01);
        Date lastWorkingDay2 = Duration.toMonthEnd(setembro);
        system.debug('TESTE LAST WORKING DAY ' + lastWorkingDay2.day()+' == 28 ');
        //system.assert( lastWorkingDay2.day() == 28 );
        //O ultimo dia de trabalho de setembro é o dia 28 porque 29 é sábado e 30 e domingo.

        //Agosto de 2019 acaba num sábado
        Date agosto2019 = Date.newInstance(2019,08,25);
        Date lateAgosto2019 = Duration.toMonthEnd(agosto2019);
        system.debug('TESTE LAST WORKING DAY ' + lateAgosto2019.day()+' == 30 ');
        //system.assert(lateAgosto2019.day() == 30);

        

    }

    public static testmethod void UnitTestDeadAccount(){
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        system.debug('Começando testes Dead Account');
        Account parentPerOrder;
        
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        
        for (Integer i=0; i<3; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        
        //Insert Parent Accounts
        parentPerOrder = TestDataHelper.createAccount();
        parentPerOrder.InvoiceFrequency__c = 'Per Order';
        INSERT parentPerOrder;
        Account location =  TestDataHelper.insertLocation(parentPerOrder.Id, null);

        //Insert Child Accounts
        Account an1 =[SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c FROM  Account WHERE InvoiceFrequency__c = 'Per Order' LIMIT 1];
        
        //Insert Orders for Per Order
        Order Ord1 = new Order(
            AccountId = location.id,
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
            AccountId = location.id,
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
        Ord2.Status = 'Delivered';
        Ord1.Status = 'Delivered';
        upsert Ord1; upsert Ord2;
        
        List<Invoice_Header__c> newHeaders1 = [SELECT Id, OrderLookUp__c  FROM Invoice_Header__c where OrderLookUp__c = :Ord1.Id];
        List<Invoice_Header__c> newHeaders2 = [SELECT Id, OrderLookUp__c  FROM Invoice_Header__c where OrderLookUp__c = :Ord2.Id];
        System.debug('newHeaders1.size() = ' + newHeaders1.size());
        System.debug('newHeaders2.size() = ' + newHeaders2.size());
        //System.assert( newHeaders1.size()==0 );
        //System.assert( newHeaders2.size()==0 );
        
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
    } 

    public static testmethod void SecureDestructions(){
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        system.debug('Começando testes Secure Destructions');
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        system.debug('Criar Produtos SKIN:: ');
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProductSkin('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
         
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
          
        for (Integer i=0; i<3; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        
        //Insert Parent Accounts
        Account parentPerOrder = TestDataHelper.createAccount();
        parentPerOrder.InvoiceFrequency__c = 'Per Order';
        INSERT parentPerOrder;
        Account location = TestDataHelper.insertLocation(parentPerOrder.Id, null);

        //Insert Orders for Per Order
        Order ord1 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        insert ord1;

        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 0
        ));
        insert lstOLI;

        ord1.Status = 'Delivered';
        system.debug('ORDEM DELIVERED COM SKIN SECURE DESTRUCTION NO PRODUCT SKIN');
        upsert ord1;
}

    public static testmethod void ConsignmentNotes(){
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        
        system.debug('Começando testes Consignment Notes');
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        system.debug('Criar Produtos SKIN:: ');
        for (Integer i=0; i<3; i++) {
            lstProds.add(createTestProductSkinNote('Prod-' + (i+1), 10, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        
        for (Integer i=0; i<3; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        
        //Insert Parent Accounts
        Account parentPerOrder = TestDataHelper.createAccount();
        parentPerOrder.InvoiceFrequency__c = 'Per Order';
        INSERT parentPerOrder;
        Account location = TestDataHelper.insertLocation(parentPerOrder.Id, null);

        //Insert Orders for Per Order
        Order ord1 = new Order(
            AccountId = location.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        insert ord1;

        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 0
        ));
        insert lstOLI;
        system.debug(lstOLI);

        ord1.Status = 'Delivered';
        system.debug('ORDEM DELIVERED COM SKIN SECURE DESTRUCTION NO PRODUCT SKIN');
        upsert ord1;



}

    private static Product2 createTestProductSkin(String prodName, Integer recycleKG, Integer idx) {
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
        insert proCat;

        List <Product_Skin__c> product_skins =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE '%Sec Destr%'];
        system.debug('Existem ' + product_skins.size() + ' Product Skins com Sec Destr no nome'); 
        Product_Skin__c product_skin = product_skins.get(0); 

        //system.debug('SKIN:: '+n.get(0)+'Name::::'+n.get(0).Name);
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        
        Product2 prod = new Product2(
            Name = prodName,  
            Product_Type__c = 'Delivery',
            Report_Groupings__c = rpGroup,
            Recycle_KG__c = recycleKG,
            Product_Skins__c = product_skin.Id,
            IsActive = true,
            Product_Category__c = proCat.Id,
            UnitCost__c = 10,
            ProductCode = '123',
            Nl_accode__c = '4001'
        );        
        //prod.Product_Skins__c = n.Id;
        //system.debug('SAI do create test product SKIN');
        return prod;
    }

    private static Product2 createTestProductSkinNote(String prodName, Integer recycleKG, Integer idx) {
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
        insert proCat;

        List <Product_Skin__c> product_skins =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE '%WEEE%' OR Name LIKE '%Batteries%'];
        system.debug('Existem ' + product_skins.size() + ' Product Skins com WEEE no nome'); 
        Product_Skin__c product_skin = product_skins.get(0);

        //system.debug('SKIN:: '+n.get(0)+'Name::::'+n.get(0).Name);
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
		prod.Product_Skins__c = product_skin.Id;     
        
        return prod;
    }
}