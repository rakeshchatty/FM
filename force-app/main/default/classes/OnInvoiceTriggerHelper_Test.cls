@isTest
private class OnInvoiceTriggerHelper_Test {

	@testSetup
	static void setup() {
		TestDataHelper.insertVat();

		Account parentAccount = TestDataHelper.createAccount();
		parentAccount.Enqix_Payment_Method__c='Account';
		parentAccount.CreditDays__c = '30';
		parentAccount.Enqix_Dead_Live__c = 'Live';
		parentAccount.Price_Book__c =  Test.getStandardPricebookId();
		parentAccount.InvoiceFrequency__c = 'Per Order';
		INSERT parentAccount;

		Account locationAccount = TestDataHelper.insertLocation(parentAccount.Id, null);

		Invoice_Header__c ih = new Invoice_Header__c();
		ih.Name = 'test invoice header';
		ih.Account__c = parentAccount.Id;
		ih.InvoiceFrequency__c = 'Per Order';
		insert ih;
		system.debug('New Header '+ih);

		Invoice_Line__c il = new Invoice_Line__c();
		il.Name = 'test invoice line';
		il.Invoice_HeaderId__c = ih.Id;
		insert il;
		system.debug(il);

		Suppliers__c supp = new Suppliers__c();
		supp.Name = 'test supplier';
		supp.Phone_Number__c = '123456789';
		insert supp;

        TestDataHelper.insertSupplier('First Mile Ltd');
	}

	@isTest 
    static void test_method_one() {
        
        
		Account a =[SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c FROM  Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];


        system.debug('Account added: '+ a);
        
        List <Contact> contList = new List<Contact>();
        
        Contact c1 = new Contact();
        c1.AccountId = a.id;
        c1.Email = 'firstmile.support@xpand-it.com';
        c1.Contact_Role__c = 'Finance Contact';
        c1.LastName = 'IT';
        c1.FirstName = 'Xpand';
        contList.add(c1);
        
        Contact c2 = new Contact();
        c2.AccountId = a.id;
        c2.Email = 'firstmile.support@xpand-it.com.invalid';
        c2.LastName = 'IT';
        c2.FirstName = 'XPAND';
        contList.add(c2);
        
        insert contList;
        
        Id pricebookId = Test.getStandardPricebookId();
        
		Order Ord1 = new Order(
            AccountId = a.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(+(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert Ord1;

        String newID = ''+ Ord1.id;
        
        Product_Category__c pc = new Product_Category__c();
        pc.Name = 'test';
        pc.Enqix_Id__c = 1;
        pc.Product_Category_Key__c = 'test';
        insert pc;
        
        Product2 prod = new Product2(Name = 'Laptop X200', Family = 'Hardware',Product_Category__c = pc.id,ProductCode='333',Product_Type__c='Delivery',Enqix_Id__c = '1', IsActive=true, Nl_accode__c = 'teste123');
        insert prod;
              
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        
        lstStandardPrice.add(new PricebookEntry(
            Pricebook2Id = pricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        )
                             
                            );
        insert lstStandardPrice;
        
        List<OrderItem> lstOLI = new List<OrderItem>();        
        OrderItem OrdItem1 = new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 10,
            UnitPrice = 10,
            ProductDiscount__c = 5,
            Manual_Product_Name__c = 'teste',
            Partner_Unit_Price__c = 5,
            Product2Id = prod.Id,
            Price_Book__c = pricebookId,
            PricebookEntryId = lstStandardPrice.get(0).Id
        );
        lstOLI.add(OrdItem1);
        
        OrderItem OrdItem2 = new OrderItem(
            OrderId = Ord1.Id,
            Quantity = 10,
            UnitPrice = 10,
            ProductDiscount__c = 5,
            Manual_Product_Name__c = 'teste1',
            Partner_Unit_Price__c = 5,
            Product2Id = prod.Id,
            Price_Book__c = pricebookId,
            PricebookEntryId = lstStandardPrice.get(0).Id
        );
        lstOLI.add(OrdItem2);
        insert lstOLI;
        
		Date yesterday = System.today() - 1;
        List<Invoice_Header__c> headersToinsert1 = new List<Invoice_Header__c>();
       
		Invoice_Header__c ih1 = new Invoice_Header__c();
		ih1.Name = 'test invoice header';
		ih1.Account__c = a.Id;
        ih1.AmountOutstanding__c = 100;
        ih1.Vat__c = 100;
        ih1.Status__c = 'Invoiced';
        ih1.AmountExclVAT__c = 100;
        ih1.AmountOutstanding__c = 200;
        ih1.Salesforce__c = false;
        ih1.DueDate__c = yesterday;
        ih1.Ready_to_Email__c = true;
        ih1.OrderIds__c = newID;
        ih1.CreatedDate = yesterday;
        ih1.InvoiceFrequency__c  = 'Per order';
        ih1.Payment_Reference__c = 'ch_1DpwAELlI9xY5rES7ST38i9o';	
        headersToinsert1.add(ih1);
        
        system.debug('New Invoice Header: '+ih1);
        
        Invoice_Header__c ih2 = new Invoice_Header__c();
		ih2.Name = 'test invoice header';
		ih2.Account__c = a.Id;
        ih2.AmountOutstanding__c = 200;
        ih2.Status__c = 'Invoiced';
        ih2.AmountExclVAT__c = 200;
        ih2.Vat__c = 50;
        ih2.OrderIds__c = newID;
        ih2.Salesforce__c = true;
        ih2.DueDate__c = yesterday;
        ih2.Ready_to_Email__c = true;
        ih2.CreatedDate = yesterday;
        ih2.InvoiceFrequency__c  = 'Per order';
        ih2.Payment_Reference__c = 'ch_1DpwAELlI9xY5rES7ST38i9o123';      
        headersToinsert1.add(ih2);
        
        system.debug('New Invoice Header: '+ih2);

		insert headersToinsert1;  
        Test.setCreatedDate(ih1.Id, yesterday);
        Test.setCreatedDate(ih2.Id, yesterday);
        
        Test.startTest();
        List <Invoice_Line__c> invsLines = new List<Invoice_Line__c>();
        
        Invoice_Line__c il2 = new Invoice_Line__c();
        il2.Name = 'test invoice line';
        il2.Invoice_HeaderId__c = ih1.Id;
        il2.Order__c = Ord1.Id;
        il2.Amount__c = 123;
        il2.VAT__c = 12;
        il2.SageExtractCreated__c = false;
        il2.Product__c = prod.Id;
        invsLines.add(il2); 
        
        Invoice_Line__c il1 = new Invoice_Line__c();
        il1.Name = 'test invoice line1';
        il1.Invoice_HeaderId__c = ih2.Id;
        il1.Order__c = Ord1.Id;
        il1.Amount__c = 123;
        il1.VAT__c = 12;
        il1.Product__c = prod.Id;
        invsLines.add(il1);
        
        insert invsLines;

		Database.executebatch(new SageExtractFromInvoiceBatch(), 200);

        ih1 = [SELECT Id, Payment_Due_Date__c, Ready_to_Email__c, (SELECT Id, ProductAnalysisCode__c, Amount__c, VAT__c, Order__c, Delivery_Date__c FROM Invoice_Lines__r) FROM Invoice_Header__c where Id = :ih1.Id limit 1];

        List <Invoice_Header__c> invoicesToPay = new List <Invoice_Header__c>();
        Invoice_Header__c ih3 = new Invoice_Header__c();
		ih3.Name = 'test invoice header';
		ih3.Account__c = a.Id;
        ih3.Status__c = 'Emailed';
        ih3.AmountExclVAT__c = 200;
        ih3.Vat__c = 50;
        ih3.Salesforce__c = true;
        ih3.DueDate__c = Date.newInstance(2018, 11, 11);
        ih3.Ready_to_Email__c = true;
        ih3.CreatedDate = system.today();
        ih3.InvoiceFrequency__c  = 'Per order';
        ih3.Payment_Reference__c = 'ch_1DpwAELlI9xY5rES7ST38i9o';
        ih3.AmountOutstanding__c = 10;
        ih3.Query__c = false;
        
        invoicesToPay.add(ih3);
        insert invoicesToPay;
        
        Bank_Statement__c bs = new Bank_Statement__c(
        	Unallocated_Amount__c = -200,
            Account__c = a.Id,
            //CP_Transactional_Info__c = 'ch_1DpwAELlI9xY5rES7ST38i9o',
            Transaction_Type__c = 'Credit Card',
            fromCustomerPortal__c = true,
            Document_name__c = 'testDocument',
            Entry_Date__c = system.today(),
            Transaction_Details__c = 'detail'
        );        
        //insert bs;
        
        List <Invoice_Header__c> invoicesToProcess = new List <Invoice_Header__c>();
        
        Invoice_Header__c ih4 = new Invoice_Header__c();
		ih4.Name = 'test invoice header';
		ih4.Account__c = a.Id;
        ih4.Status__c = 'Emailed';
        ih4.AmountExclVAT__c = 200;
        ih4.Vat__c = 50;
        ih4.Salesforce__c = true;
        ih4.DueDate__c = Date.newInstance(2018, 11, 11);
        ih4.Ready_to_Email__c = true;
        ih4.CreatedDate = system.today();
        ih4.InvoiceFrequency__c  = 'Per order';
        ih4.Payment_Reference__c = 'ch_1DpwAELlI9xY5rES7ST38i9o';
        ih4.AmountOutstanding__c = -10;
        ih4.Query__c = false;
        
        invoicesToProcess.add(ih4);
        insert invoicesToProcess;
        
        List <Invoice_Line__c> invoicesLinesToProcess = new List <Invoice_Line__c>();
        
        Invoice_Line__c il3 = new Invoice_Line__c();
        il3.Name = 'test invoice line';
        il3.Invoice_HeaderId__c = ih4.Id;
        il3.Order__c = Ord1.Id;
        il3.Amount__c = 123;
        il3.VAT__c = 12;
        il3.SageExtractCreated__c = false;
        il3.Product__c = prod.Id;
        invoicesLinesToProcess.add(il3); 
        
        Invoice_Line__c il4 = new Invoice_Line__c();
        il4.Name = 'test invoice line1';
        il4.Invoice_HeaderId__c = ih4.Id;
        il4.Order__c = Ord1.Id;
        il4.Amount__c = 123;
        il4.VAT__c = 12;
        il4.Product__c = prod.Id;
        invoicesLinesToProcess.add(il4);
        
        insert invoicesLinesToProcess;
        
        /*Bank_Statement__c bs1 = new Bank_Statement__c(
        	Unallocated_Amount__c = -20,
            Account__c = a.Id,
            //CP_Transactional_Info__c = 'ch_1DpwAELlI9xY5rES7ST38i9o',
            Transaction_Type__c = 'Credit Note',
            fromCustomerPortal__c = true,
            Document_name__c = 'testDocument',
            Entry_Date__c = system.today(),
            Transaction_Details__c = 'detail',
            Credit_Note_Invoice__c = ih4.Id
        );        
        insert bs1;*/
        
        //delete il1;

        //InvoiceHeaderTriggerHelper.CreateSageExtract(headersToinsert1);
       
        //test.startTest();
        
        Task t = new Task();
        //t.OwnerId = UserInfo.getUserId();
        t.Subject = 'Invoice Emailed -Test';
        t.Status = 'Completed';
        t.WhatId = ih1.Id;
        insert t;
        system.debug(t);

        Invoicing.createLines(headersToinsert1);
        //InvoiceHeaderTriggerHelper.payInvoices(invoicesToPay);
        InvoiceHeaderTriggerHelper.processCreditNotes(invoicesToProcess);        
        
        delete invoicesLinesToProcess;

        test.stopTest();
	}

    @isTest
    static void payInvoiceTest() {
        Account parent = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Account'];
        Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location'];
        
        Order order = TestDataHelper.createOrder(location.Id, System.today());
        INSERT order;
        
        Product2 product = TestDataHelper.createProduct('Test Name', 'Test Code', 'Collection');
		INSERT product;
        
        PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
        
        OrderItem orderitem = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
        INSERT orderitem;
        
        order.Delivery_Date__c = System.today();
        order.Status = 'Delivered';
        order.CreditCard_Payment__c = true;
        UPDATE order;
        
        Bank_Statement__c bankstatement = new Bank_Statement__c();
        bankstatement.Account__c = parent.Id;
        bankstatement.Entry_Date__c = System.today();
        bankstatement.Transaction_Type__c = 'Credit Card';
        bankstatement.Receipt_Amount__c = 78;
        bankstatement.Unallocated_Amount__c = 78;
        bankstatement.CP_Transactional_Info__c = 'test';
        bankstatement.Document_name__c = 'test';
        bankstatement.Transaction_Details__c = 'test';
        Test.startTest();
        INSERT bankstatement;
        Test.stopTest();
    }
}