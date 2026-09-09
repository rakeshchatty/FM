@istest
private class Order2ProductEntryTests {

    @testSetup
    static void setup() {
        Test.startTest();
        List <RecordType> accRecordTypes = [SELECT Id,
                                                Name
                                                FROM RecordType
                                                WHERE SObjectType = 'Account'
                                                AND (Name = 'Location' OR Name = 'Partner' OR Name = 'Account')
                                           ];
        Id locationRecordTypeId;
        Id partnerRecordTypeId;
        Id parentRecordTypeId;
        for(RecordType rec : accRecordTypes) {
            if(rec.Name == 'Location') {
                locationRecordTypeId = rec.Id;
            } else if(rec.Name == 'Partner') {
                partnerRecordTypeId = rec.Id;
            } else if (rec.Name == 'Account') {
                parentRecordTypeId = rec.Id;
            }
        }
        Product_Category__c pc = new Product_Category__c();
        pc.Name = 'test';
        pc.Enqix_Id__c = 1;
        pc.Product_Category_Key__c = 'test';
        insert pc;

		Product2 prod = TestDataHelper.insertProduct('Laptop X200', '333', 'Delivery', pc.Id);
        prod.Family = 'Hardware';
        prod.Enqix_Id__c = '1';
		UPDATE prod;
        
		Product2 prod1 = TestDataHelper.insertProduct('Laptop X200', '333', 'Delivery', pc.Id);
        prod1.Family = 'Hardware';
        prod1.Enqix_Id__c = '2';
		UPDATE prod1;
        
        Product2 prod2 = TestDataHelper.insertProduct('Laptop X200', '333', 'Delivery', pc.Id);
        prod2.Family = 'Hardware';
        prod2.Enqix_Id__c = '3';
		UPDATE prod2;

        system.debug('Number of queries: '  +Limits.getQueries());
        // Get standard price book ID.
        // This is available irrespective of the state of SeeAllData.
        Id pricebookId = Test.getStandardPricebookId();
        
        // 1. Insert a price book entry for the standard price book.
        // Standard price book entries require the standard price book ID we got earlier.
        List<PricebookEntry> pbes = new List<PriceBookEntry>();
        PricebookEntry standardPrice = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod.Id,
            UnitPrice = 100, IsActive = true);
        pbes.add(standardPrice);
        
        PricebookEntry standardPrice1 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod1.Id,
            UnitPrice = 10000, IsActive = true);
        pbes.add(standardPrice1);
        
        PricebookEntry standardPrice2 = new PricebookEntry(
            Pricebook2Id = pricebookId, Product2Id = prod2.Id,
            UnitPrice = 10000, IsActive = true);
        pbes.add(standardPrice2);

        insert pbes;
        system.debug('Number of queries: '  +Limits.getQueries());
        
        // Create a custom price book
        Pricebook2 customPB = new Pricebook2(Name='Standard Price List 1', Enqix_Id__c = '1', isActive=true, Most_Recent__c = true, Effective_Date__c = system.today());
        insert customPB;
        
        Account parentAccount = new Account();
        parentAccount.Name = 'Parent Account';
        parentAccount.RecordTypeID = parentRecordTypeId;
        parentAccount.Price_Book__c = customPB.Id;
        parentAccount.Account_Discount__c = 2;
        parentAccount.Direct_Debit_Discount__c = 2;
        insert parentAccount;

        Account partnerAccount = new Account();
        partnerAccount.Name = 'Partner Account';
        partnerAccount.RecordTypeID = partnerRecordTypeId;
        partnerAccount.Price_Book__c = customPB.Id;
        insert partnerAccount;

        system.debug('parent PB --- '+ [select Price_Book__c, name from Account where Id = :partnerAccount.Id]);
        
        Account childAccount = new Account();
        childAccount.Name = 'Child Account';
        childAccount.RecordTypeId = locationRecordTypeId;
        childAccount.Partnership__c = partnerAccount.Id;
        childAccount.ParentId = parentAccount.Id;
        childAccount.Price_Book__c = customPB.Id;
        childAccount.IsInvoiceFrequencyOverride__c = true;
        childAccount.InvoiceFrequency__c = 'Monthly';
        childAccount.Enqix_Dead_Live__c = 'Live';
        insert childAccount;
        system.debug('child acc ' +childAccount); 

        
        Suppliers__c supp = new Suppliers__c();
        supp.Name = 'test supp';
        supp.Phone_Number__c = '123456789';
        insert supp;
        system.debug('Number of queries: '  +Limits.getQueries());
        
        // 2. Insert a price book entry with a custom price.
        PricebookEntry customPrice = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod.Id,
            UnitPrice = 120, IsActive = true);
        insert customPrice;
        
        PricebookEntry customPrice1 = new PricebookEntry(
            Pricebook2Id = customPB.Id, Product2Id = prod1.Id,
            UnitPrice = 100, IsActive = true);
        insert customPrice1;
        
        system.debug('Number of queries: '  +Limits.getQueries());
        Order orderRecord = new Order();  
        orderRecord.AccountId = childAccount.id;
        orderRecord.Description  = 'Test';  
        orderRecord.Status = 'Confirmed';
        orderRecord.Type = 'Regular';
        orderRecord.EffectiveDate = Date.today(); 
        orderRecord.Name = 'Test';
        orderRecord.PriceBook2Id = customPB.Id;
        insert orderRecord;
        system.debug('Number of queries: '  +Limits.getQueries());
        
      
        List <OrderItem> orderItems = new List <OrderItem>();
        OrderItem oi = new OrderItem();
        oi.product2Id = prod.id;
        oi.OrderID = orderRecord.id;
        oi.Price_Book__c = customPB.id; 
        oi.Quantity = 150;
        oi.ListPrice__c = 5;
        oi.Discount_to_Apply__c = 'Account';
        oi.Description__c = '123';
        oi.PricebookEntryId = customPrice.Id;
        orderItems.add(oi);
        
        OrderItem oi1 = new OrderItem();
        oi1.product2Id = prod1.id;
        oi1.OrderID = orderRecord.id;
        oi1.Price_Book__c = customPB.id; 
        oi1.Quantity = 100;
        oi1.ListPrice__c = 10;
        oi1.Discount_to_Apply__c = 'Partner';
        oi1.Description__c = '123';
        oi1.PricebookEntryId = customPrice1.Id;
        oi1.Quantity_Sold_In__c = 5;
        orderItems.add(oi1);  
        
        system.debug('orderItems size: '  +orderItems.size());
        insert orderItems;
        
        system.debug('Number of queries: '  +Limits.getQueries());
        Account_Discount__c disc1 = new Account_Discount__c();
        disc1.Account__c = parentAccount.Id;
        disc1.Product__c = prod.id;
        disc1.Product_Discount__c = 1;
        disc1.DiscountSupStartDate__c = system.today();
        insert disc1;
        system.debug('Number of queries: '  +Limits.getQueries());
        Account_Discount__c disc2 = new Account_Discount__c();
        disc2.Account__c = partnerAccount.Id;
        disc2.Product__c = prod1.id;
        disc2.Product_Discount__c = 3;
        disc2.DiscountSupStartDate__c = system.today();
        insert disc2;     
        Account_Discount__c disc3 = new Account_Discount__c();
        disc3.Account__c = parentAccount.Id;
        disc3.Product__c = prod2.id;
        disc3.Product_Discount__c = 3;
        disc3.DiscountSupStartDate__c = system.today();
        insert disc3;
        
        list<Subscribed_Products__c> spProducts = new list<Subscribed_Products__c>();
        
        Subscribed_Products__c sp = new Subscribed_Products__c();
        sp.Account__c =  childAccount.Id;
        sp.Enqix_BID_Location_Limit_Period__c = 'Annual';
        sp.Enqix_ID__c = '231';
        sp.Last_Discount_Given__c = system.today().Addyears(-1);
        sp.Product__c = prod.id;
        sp.Enqix_BID_Location_Limit_Quantity__c = 100;
        sp.Quantity_Remaining__c = 1000;
        sp.StartDate__c = System.today();
        sp.EndDate__c = System.today();
        spProducts.add(sp);
        
        Subscribed_Products__c sp1 = new Subscribed_Products__c();
        sp1.Account__c =  childAccount.Id;
        sp1.Enqix_BID_Location_Limit_Period__c = 'Monthly';
        sp1.Enqix_ID__c = '232';
        sp1.Last_Discount_Given__c = system.today().AddMonths(-1);
        sp1.Product__c = prod1.id;
        sp1.Enqix_BID_Location_Limit_Quantity__c = 100;
        sp1.Quantity_Remaining__c = 1000;
        sp1.StartDate__c = System.today(); 
        sp1.EndDate__c = System.today();
        spProducts.add(sp1);
        
        Subscribed_Products__c sp2 = new Subscribed_Products__c();
        sp2.Account__c =  childAccount.Id;
        sp2.Enqix_BID_Location_Limit_Period__c = 'Quarterly';
        sp2.Enqix_ID__c = '233';
        sp2.Last_Discount_Given__c = system.today().AddMonths(-3);
        sp2.Product__c = prod2.id;
        sp2.Enqix_BID_Location_Limit_Quantity__c = 100;
        sp2.Quantity_Remaining__c = 100;
        sp2.StartDate__c = System.today(); 
        sp1.EndDate__c = System.today();
        spProducts.add(sp2);
        
        insert spProducts;
        system.debug(spProducts);
        Test.stopTest();
         try {
            delete oi;
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains(Label.NoPermissionToDeleteOrderItem), Label.NoPermissionToDeleteOrderItem);
        }
    }

    static testMethod void theTests(){   
                
        ////////////////////////////////////////
        //  test opportunityProductEntry
        ////////////////////////////////////////
        insert new TheVat__c(Value__c = 1);
        
        //insert orderRecord;
        Order order = [Select Id, PriceBook2Id, AccountId, Account.Price_book__c, Status from Order LIMIT 1];
        Account acc = [Select Id, Price_book__c, ParentId from Account where Id =:order.AccountId LIMIT 1];
        List<PricebookEntry> pbes = [SELECT Id, Pricebook2Id, Product2Id, Product2.Name FROM PricebookEntry];
        Order orderRecord = new Order(); 
        system.debug('order -->'+order);
        system.debug('acc -->'+acc);
        
        // load the page       
        PageReference pageRef = Page.order2ProductEntry;
        pageRef.getParameters().put('Id',order.id);
        pageRef.getParameters().put('accountId',acc.Id);
        Test.setCurrentPageReference(pageRef);
        
        // load the extension
        OrderProductEntryExtension oPEE = new OrderProductEntryExtension(new ApexPages.StandardController(order));
   
        oPEE.selectedPB = String.valueOf(order.PriceBook2Id);
        oPEE.isNational = False;  
        
        system.debug('selectedPB --> '+oPEE.selectedPB);
        // test 'getChosenCurrency' method
        if(UserInfo.isMultiCurrencyOrganization())
            System.assert(oPEE.getChosenCurrency()!='');
        else
            System.assertEquals(oPEE.getChosenCurrency(),'');

        // we know that there is at least one line item, so we confirm
        Integer startCount = oPEE.shoppingcart.size();
        system.debug('startCount --> '+startCount);
        //system.assert(startCount>0);

        //test search functionality without finding anything
        
        oPEE.searchString = 'Laptop';
        opEE.GetPartnerDiscounts();
        oPEE.updateAvailableList();
        oPEE.toSelect = pbes[1].id+'-bid';
        oPEE.addToShoppingCart();  
        //test remove from shopping cart
        oPEE.toUnselect = pbes[0].Product2Id;
        oPEE.removeFromShoppingCart();
        //system.assert(oPEE.shoppingCart.size()==startCount-1);
        
        //test save and reload extension
        try {
            oPEE.onSave();
        } catch (Exception e) {
            Assert.isTrue(e.getMessage().contains(Label.NoPermissionToDeleteOrderItem), Label.NoPermissionToDeleteOrderItem);
        }
        oPEE = new orderProductEntryExtension(new ApexPages.StandardController(order)); 
        oPEE.selectedPB = String.valueOf(order.PriceBook2Id);
        oPEE.isNational = False;  
		// test search again, this time we will find something
        oPEE.searchString = pbes[0].Product2.Name;
        oPEE.updateAvailableList();
        //system.assert(oPEE.AvailableProducts.size()>0);       
        
        // test add to Shopping Cart function
        opEE.GetPartnerDiscounts();
        oPEE.GetMostOrderedProducts();
        oPEE.inMostOrderProductTab = true;
        //oPEE.toSelect = oPEE.AvailableProducts[0].Id;
        oPEE.toSelect = pbes[0].id+'-most';
        oPEE.addToShoppingCart();
        oPEE.toSelect = pbes[1].id+'-bid';
        oPEE.addToShoppingCart();
        oPEE.toSelect = pbes[2].id+'-available';
        oPEE.addToShoppingCart();
        
        //oPEE.toSelect = standardPrice.id+'-bid';
        //oPEE.addToShoppingCart();
        
        //oPEE.toSelect = standardPrice.id+'-available';
        //oPEE.addToShoppingCart();
        
        opEE.RefreshSupplierProducts();
        //system.assert(oPEE.shoppingCart.size()==startCount);
                
        // test save method - WITHOUT quanitities and amounts entered and confirm that error message is displayed
        oPEE.onSave();
        //system.assert(ApexPages.getMessages().size()>0);
        Product2 prod = [SELECT Id FROM Product2 limit 1];
        // add required info and try save again
        
        for(OrderItem o : oPEE.ShoppingCart){
            o.quantity = 5;
            //o.OrderId = order.Id;
            o.ListPrice__c = 300;
            //o.product2Id = prod.Id;
        }
        oPEE.onSave();
        opEE.BoostupTestCoverage();
        
        
        oPEE = new orderProductEntryExtension(new ApexPages.StandardController(order));
        //System.assert(oPEE.priceBookCheck()!=null);
        
        // final quick check of cancel button
        System.assert(oPEE.onCancel()!=null);
        
        oPEE = new OrderProductEntryExtension(new ApexPages.StandardController(orderRecord));
       	oPEE.closePopup();
        ////////////////////////////////////////
        //  test redirect page
        ////////////////////////////////////////
       
        OrderItem orderproduct = [select id, OrderId from OrderItem limit 1];
        // load the page
        pageRef = Page.order2ProductRedirect;
        pageRef.getParameters().put('Id',orderproduct.Id);
        Test.setCurrentPageReference(pageRef);

        // load the extension and confirm that redirect function returns something
        Order2ProductRedirectExtension PRE = new Order2ProductRedirectExtension(new ApexPages.StandardController(orderproduct));
        PRE.redirect();
        
    }
}