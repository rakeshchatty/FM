@isTest
public with sharing class RecurringTest {
    public static testmethod void test() {
        TestDataHelper.insertSupplier('First Mile Ltd');
        Account acc;
        Account parent;

        //Products
        List < Product2 > lstProds = new List < Product2 > ();

        for (Integer i = 0; i < 5; i++) {
            lstProds.add(createTestProduct('Prod-' + (i + 1), 10, (i + 1), 8765 + i));
        }
        insert lstProds;

        Pricebook2 standardPricebook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true,
            Effective_Date__c = System.today()
        );

        // Run an update DML on the Pricebook2 record
        // This is the weird workaround that enables IsStandard to become true
        // on the PricebookEntry record
        update standardPricebook;
		System.debug('StrandardPriceBook --->' + standardPricebook);
        List < PricebookEntry > lstStandardPrice = new List < PricebookEntry > ();

        for (Integer i = 0; i < 5; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = standardPricebook.Id,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        System.debug('lstStandardPrice ---->' + lstStandardPrice);

        //Inserir accounts
        parent = new Account(Name = 'Sample Monthly Parent Account', 
                                InvoiceFrequency__c = 'Monthly',
                                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId(),
                             	Price_book__c = standardPricebook.Id,
                             	Enqix_Dead_Live__c = 'Live'
                            );
        insert parent;
        parent = [Select Id from Account where Name = 'Sample Monthly Parent Account'];
		
        //Insert Child Accounts
        acc = new Account(Name = 'Sample Monthly Child Account 1',
                            ParentId = parent.id,
                            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId(),
                          	Price_book__c = standardPricebook.Id,
                          	Enqix_Dead_Live__c = 'Live'
                        );
        insert acc;
        //parent = [Select Id from Account where Name = 'Sample Monthly Child Account 1'];
        System.debug('PriceBook Teste' + acc.Price_book__c);

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
            Pricebook2Id = standardPricebook.Id
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
            Pricebook2Id = standardPricebook.Id
        );
        insert ord2;



        //order Items
        List < OrderItem > lstOLI = new List < OrderItem > ();
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
        System.debug('lstOLI ---->' + lstOLI);
        lstProds.get(1).Name = 'test product name';
        update lstProds.get(1);
        
        Suppliers__c supp = new Suppliers__c(
            Name = 'Test supp',
            Phone_Number__c = '12332132'
        );
        insert supp;

        Recurrings__c first_recurring = new Recurrings__c(
            Account__c = acc.Id,
            Active__c = true,
            First_Date__c = Date.newInstance(2018, 09, 01),
            Product__c = lstProds.get(2).Id,
            Quantity__c = 2,
            Recur_every__c = '2',
            Rec__c = 'Day',
            Name = 'Test_Recurring',
            Type__c = 'Invoicing',
            Price_Book__c = standardPricebook.Id,
            Supplier__c = supp.Id
        );
        insert first_recurring;

        Recurrings__c recurring = new Recurrings__c(
            Account__c = acc.Id,
            Active__c = false,
            First_Date__c = Date.newInstance(2018, 09, 03),
            Product__c = lstProds.get(2).Id,
            Quantity__c = 2,
            Recur_every__c = '2',
            Rec__c = 'Week',
            Name = 'Test_Recurring1',
            Type__c = 'Invoicing',
            Price_Book__c = standardPricebook.Id
        );
        insert recurring;

        Recurrings__c recurring2 = new Recurrings__c(
            Account__c = acc.Id,
            Active__c = true,
            First_Date__c = Date.newInstance(2018, 09, 02),
            Product__c = lstProds.get(2).Id,
            Quantity__c = 2,
            Recur_every__c = '1',
            Rec__c = 'Month',
            Name = 'Test_Recurring2',
            Type__c = 'Invoicing',
            Price_Book__c = standardPricebook.Id
        );
        insert recurring2;
        
        List <Supplier_Product__c> suppProds = new List <Supplier_Product__c>();
        Supplier_Product__c suppProd1 = new Supplier_Product__c(
            Name = 'testSuppProd1',
            Start_Date__c = system.today() - 5,
            End_Date__c = system.today(),
            Enqix_UID__c = '1233321',
            Product__c = lstProds.get(2).Id,
            Supplier__c = supp.Id,
            Supplier_Price__c = 1
        );   
        suppProds.add(suppProd1);
        
        Supplier_Product__c suppProd2 = new Supplier_Product__c(
            Name = 'testSuppProd2',
            Start_Date__c = system.today() - 10,
            End_Date__c = system.today() + 10,
            Enqix_UID__c = '1233346',
            Product__c = lstProds.get(1).Id,
            Supplier__c = supp.Id,
            Supplier_Price__c = 1
        );   
        suppProds.add(suppProd2);
        insert suppProds;
        
        first_recurring.Next_Date__c = system.today();
        first_recurring.Product__c = lstProds.get(1).Id;
        update first_recurring;
        recurring.Next_Date__c = system.today();
        update recurring;
        recurring2.Next_Date__c = system.today();
        recurring2.Recur_every__c = '2';
        update recurring2;    

		suppProd1.Supplier_Price__c = 2;
        update suppProd1;
        
        //Next_Date__c = today
        System.debug('Testing the custom constructor with criteria');
        RecurringBatch b = new RecurringBatch('Active__c = TRUE And Name = \'Test_Recurring2\'');
        database.executebatch(b, 200);

        system.debug('Running the Schedule');
        RecurringSch nis = new RecurringSch();
        nis.execute(null);
    }

    private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx, Integer enqix) {

        String rpGroup = (Math.mod(idx, 2) == 0) ? 'Cardboard' : 'Food Recycling';
        Product_Category__c pcc = new Product_Category__c(Enqix_Id__c = 91,
            Name = 'test_product_category', Product_Category_Key__c = 'a123');
        insert pcc;

        Product_Skin__c pskins = new Product_Skin__c(Enqix_Id__c = 91,
            Name = 'test_product_skin');
        //insert pskins;
		
        Product2 prod = TestDataHelper.createProduct(prodName, 'test1234', 'Collection', pcc.Id, null, null, string.valueOf(enqix));
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
        prod.Product_Skins__c = pskins.Id;

        return prod;
    }
}