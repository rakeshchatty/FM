@isTest
public class XpandIT_CreditNote_Controller_Test {
	
    @testSetup
    static void makeData() {
		TestDataHelper.insertVat();

        List <RecordType> accRecordTypes = [SELECT Id,
                                                Name
                                                FROM RecordType
                                                WHERE SObjectType = 'Account'
                                                AND (Name = 'Location' OR Name = 'Partner' OR Name = 'Account')
                                           ];
        Id locationRecordTypeId;
        Id accountRecordTypeId;
        Id partnerRecordTypeId;
        for(RecordType rec : accRecordTypes) {
            if(rec.Name == 'Location') {
                locationRecordTypeId = rec.Id;
            }else if(rec.Name == 'Account') {
                accountRecordTypeId = rec.Id;
            } else if(rec.Name == 'Partner') {
                partnerRecordTypeId = rec.Id;
            }
        }
        Product_Category__c pc = new Product_Category__c();
        pc.Name = 'test';
        pc.Enqix_Id__c = 1;
        pc.Product_Category_Key__c = 'test';
        insert pc;

		Product2 prod = TestDataHelper.createProduct('Non-standard Other Charge/Credit', '333', 'Delivery', pc.Id, null, null, '1');
        prod.Family = 'Hardware';

        INSERT prod;

        system.debug('Number of queries: '  +Limits.getQueries());
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        priceBook2 priceBookRec = new priceBook2();
        priceBookRec.Name = 'Standard Price Book';
        priceBookRec.IsActive = true;
        pricebookRec.Effective_Date__c=System.Today();
        insert priceBookRec;
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        List<PricebookEntry> pbes = new List<PriceBookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 10000, IsActive = true);
        pbes.add(standardPrice);

        insert pbes;
        system.debug('Number of queries: '  +Limits.getQueries());

        Test.setMock(HttpCalloutMock.class, new DoogalTest.RestMock('TW1 2RS	51.452903	-0.317551	Postcode terminated prior to Gridlink initiative - last known ONS postcode grid reference	Twickenham	Richmond upon Thames	Twickenham Riverside	Richmond upon Thames 009C	Greater London	London	England		10.66619777679443	Urban major conurbation	Slough and Heathrow	E01003894'));
        Account parentAccount = new Account();
        parentAccount.Name = 'Parent Account';
        parentAccount.RecordTypeID = accountRecordTypeId;
        parentAccount.Price_Book__c = pricebookId;
        parentAccount.Enqix_ID__c = '1234566777';
        parentAccount.Enqix_Dead_Live__c = 'Live';
        insert parentAccount;
        
        Account partnerAccount = new Account();
        partnerAccount.Name = 'Partner Test Account';
        partnerAccount.RecordTypeId = partnerRecordTypeId;
        partnerAccount.Price_Book__c = pricebookId;
        partnerAccount.Enqix_Dead_Live__c = 'Live';
        partnerAccount.Enqix_ID__c = '1234212';
        partnerAccount.Enqix_Classification__c = 'BID'; 
        partnerAccount.InvoiceFrequency__c = 'Monthly';
        insert partnerAccount;

        Account childAccount = new Account();
        childAccount.Name = 'Test Account';
        childAccount.RecordTypeId = locationRecordTypeId;
        childAccount.BillingPostalCode = 'NW6 1NR';
        childAccount.ParentId = parentAccount.Id;
        childAccount.Enqix_Location_ID__c  = 'ABC123';
        childAccount.Price_Book__c = pricebookId;
        childAccount.Enqix_Dead_Live__c = 'Live';
        childAccount.Enqix_Classification__c = 'BID'; 
        childAccount.Enqix_ID__c = '1234';
        insert childAccount;
        
        Account childAccountPartner = new Account();
        childAccountPartner.Name = 'Test Account childPartner';
        childAccountPartner.RecordTypeId = locationRecordTypeId;
        childAccountPartner.BillingPostalCode = 'NW6 2NR';
        childAccountPartner.ParentId = parentAccount.Id;
        childAccountPartner.Enqix_Location_ID__c  = 'ABC33123';
        childAccountPartner.Price_Book__c = pricebookId;
        childAccountPartner.Enqix_Dead_Live__c = 'Live';
        childAccountPartner.Enqix_Classification__c = 'BID'; 
        childAccountPartner.Enqix_ID__c = '12323234';
        childAccountPartner.Partnership__c = partnerAccount.Id;
        insert childAccountPartner;
        
        
        
        List <Account> childAccountList = [SELECT Id, Name, ParentId, InvoiceFrequency__c, Partnership__c, Enqix_ID__c, Price_Book__c FROM  Account where RecordType.Name = 'Location' LIMIT 1];

        Suppliers__c supp = new Suppliers__c();
        supp.Name = 'test supp';
        supp.Phone_Number__c = '123456789';
        insert supp;
        test.startTest();
        system.debug('Number of queries: '  +Limits.getQueries());

        /*Order2__c order = new Order2__c();
        Order.Order_Start_Date__c = date.today();
        order.Status__c = 'Draft';
        order.Account__c = childAccount.Id;
        order.Order_Type__c = 'Contractor';
        insert order;*/
        Id partnerD = Schema.SObjectType.Account_Discount__c.getRecordTypeInfosByName().get('PartnerDiscount').getRecordTypeId();
        
        Account_Discount__c desconto = new Account_Discount__c(
			Account__c = partnerAccount.Id,
			DiscountSupStartDate__c = system.today(),
			DiscountSupEndDate__c = system.today() + 2,
			Product__c = prod.Id,
			RecordTypeId = partnerD,
			Gross_Price__c = 200,
			BID_Price__c = 10,
			Product_Discount__c = 10
		);
		insert desconto; 
        
        
        Order order = new order();
        order.EffectiveDate = date.today();
        order.Status = 'Draft';
        order.AccountId = childAccount.Id;
        order.Pricebook2Id = pricebookId;
        order.Type = 'Contractor';
        insert order;
        
        Order order2 = new order();
        order2.EffectiveDate = date.today();
        order2.Status = 'Draft';
        order2.AccountId = childAccountPartner.Id;
        order2.Pricebook2Id = pricebookId;
        order2.Type = 'Contractor';
        insert order2;
        
        
        List<OrderItem> ops = new List<OrderItem>();
        
        OrderItem op3 = new OrderItem();
        op3.Quantity = 1;
        op3.ListPrice__c = 1;
        op3.Description__c = '123';
        op3.Product2Id = prod.Id; //prod2.Id
        op3.Price_Book__c = pricebookId;
        op3.OrderId = order.Id;
        op3.Discount_to_Apply__c = 'Account';
        
        OrderItem op4 = new OrderItem();
        op4.Quantity = 1;
        op4.ListPrice__c = 1;
        op4.Description__c = '1234';
        op4.Product2Id = prod.Id; //prod2.Id
        op4.Price_Book__c = pricebookId;
        op4.OrderId = order2.Id;
        op4.Discount_to_Apply__c = 'Partner';
        ops.add(op4);
        insert ops;

        List<Order> orders = [SELECT Id, Delivery_Date__c, Status FROM Order];
        Order ord = orders.get(0);
        Order ord2 = orders.get(1);
        system.debug('order --> '+orders);
        List<OrderItem> orderProduct = [SELECT Id FROM OrderItem];
        system.debug('orderProduct --> '+orderProduct);
        
        /*ord.Created_Later__c = true;
        update ord;
        ord2.Created_Later__c = true;
        update ord2;*/
          
        test.stopTest();
        
        /*Invoice_Header__c invoice = new Invoice_Header__c (
            Name = 'Teste',
        	OrderLookUp__c = ord.Id,
            CreatedDate__c = system.today(),
            Account__c = parentAccount.Id,
            Location__c = childAccount.Id,
            DueDate__c = system.today(),
            AmountExclVAT__c = 50,
            VAT__c = 50,
            AmountInclVAT__c = 100,
            Status__c = 'Draft',
            Salesforce__c = true,
            InvoiceFrequency__c = 'Per order'
        );
        insert invoice;
        
        Invoice_Line__c invoiceLine1 = new Invoice_Line__c(Name='JRPG Inv1 Line Test Cov',
                                                         	Invoice_HeaderId__c = invoice.Id,
                                                         	Salesforce__c = true,
                                                         	Order__c = ord.Id,
                                                          	Location_Id__c=childAccount.Id,
                                                          	Amount__c=1);
        insert invoiceLine1;*/
    }
    
    @isTest
    static void test_method_one() {
        test.startTest();
        List<Invoice_Header__c> invoices = [SELECT Id, Account__c,Account__r.RecordTypeId, Location__c, InvoiceFrequency__c, Location__r.Price_Book__c, Account__r.Price_Book__c FROM Invoice_Header__c];
        System.debug('invoicesLength' + invoices.size());
        System.debug('invoicesasd' + invoices);
        Invoice_Header__c invoice = invoices.get(0);
        
        Id recordTypePartner = [SELECT RecordTypeId FROM Account WHERE Name = 'Partner Test Account'].RecordTypeId;
        System.debug('Account__r.RecordTypeId' + recordTypePartner);
        Invoice_Header__c invoicePartner = [SELECT Id, Account__c, Location__c, InvoiceFrequency__c FROM Invoice_Header__c WHERE Account__r.RecordTypeId = :recordTypePartner LIMIT 1];
        List<Invoice_Line__c> invoicesLines = [SELECT Id, Location_Id__c, Product__c FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :invoice.Id];
        system.debug('invoicesLines -->'+invoicesLines);
        //system.assertEquals(3,invoices.size()); 
        
        String test1 = XpandIT_CreditNote_Controller.getInvoiceResumeData(invoice.Id);
        //system.assertEquals(invoice.Account__c+'/Per Order', invoice.Account__c+'/'+invoice.InvoiceFrequency__c);
        
        List<Account> accounts = XpandIT_CreditNote_Controller.getAccountsLocations(invoice.Id, invoice.Account__c);
        //system.assertEquals(1, accounts.size());
         
        List<Order> orders = XpandIT_CreditNote_Controller.getLocationsOrders(invoice.Id, invoice.Location__c);
        //system.assertEquals(1, orders.size());
        
        List<OrderItem> orderProducts2 = XpandIT_CreditNote_Controller.generateCreditOrder(invoice.Id, orders.get(0).Id);
        //system.assertEquals(1, orderProducts2.size());
        
        List<OrderItem> orderProducts2_2 = XpandIT_CreditNote_Controller.generateCreditOrder(invoice.Id);
        
        List<OrderItem> orderProductsPartner = XpandIT_CreditNote_Controller.generateCreditOrder(invoicePartner.Id);
        //system.assertEquals(1, orderProducts2_2.size());
        Boolean worked = XpandIT_CreditNote_Controller.createCreditOrder(orderProducts2_2, 'notes', invoice.Id, invoice.Location__c,false);
        //system.assertEquals(true, worked);
        Boolean workedPartner = XpandIT_CreditNote_Controller.createCreditOrder(orderProducts2, 'notes', invoicePartner.Id, invoicePartner.Account__c,true);
        //system.assertEquals(true, worked);

        Boolean simpleNoteWorked = XpandIT_CreditNote_Controller.createSimpleCreditOrder(10, 'notes', invoice.Id, invoice.Location__c);
        //system.assertEquals(true, simpleNoteWorked);
        test.stopTest();
    }
   
    
}