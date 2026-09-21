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
        
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');

        Facility__c facility = TestDataHelper.insertFacility('Facility');
		TestDataHelper.insertWasteDestination(facility.Id, Date.today().addDays(-30), Date.today().addDays(30), 'BATTERIES', 'Liquid');

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
            Supplier__c = supplier.Id,
            Facility__c = facility.Id,
            Discount_to_Apply__c = 'Account'
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
            Price_Book__c = standardPricebook.Id,
            Facility__c = facility.Id,
            Discount_to_Apply__c = 'Account'
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
            Price_Book__c = standardPricebook.Id,
            Facility__c = facility.Id,
            Discount_to_Apply__c = 'Account'
        );
        insert recurring2;
        
        List <Supplier_Product__c> suppProds = new List <Supplier_Product__c>();
        Supplier_Product__c suppProd1 = new Supplier_Product__c(
            Name = 'testSuppProd1',
            Start_Date__c = system.today() - 5,
            End_Date__c = system.today(),
            Enqix_UID__c = '1233321',
            Product__c = lstProds.get(2).Id,
            Supplier__c = supplier.Id,
            Supplier_Price__c = 1
        );   
        suppProds.add(suppProd1);
        
        Supplier_Product__c suppProd2 = new Supplier_Product__c(
            Name = 'testSuppProd2',
            Start_Date__c = system.today() - 10,
            End_Date__c = system.today() + 10,
            Enqix_UID__c = '1233346',
            Product__c = lstProds.get(1).Id,
            Supplier__c = supplier.Id,
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
        prod.Service_Type__c = 'BATTERIES';
        prod.Service_Subtype__c = 'Liquid';

        return prod;
    }

    // CRMFM-2: RestrictDiscountToApply now also blocks Manual Price + Discount to Apply both blank
    @testSetup
    static void setupCrmfm2TestData() {
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd - CRMFM2');
        Facility__c facility = TestDataHelper.insertFacility('Facility - CRMFM2');

        Account parent = new Account(
            Name = 'CRMFM-2 Parent Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId(),
            Enqix_Dead_Live__c = 'Live'
        );
        insert parent;

        Account location = new Account(
            Name = 'CRMFM-2 Location Account',
            ParentId = parent.Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId(),
            Enqix_Dead_Live__c = 'Live'
        );
        insert location;

        Product2 product = createTestProduct('CRMFM2-Prod', 10, 1, 9999);
        product.IsActive = true;
        insert product;
    }

    @isTest
    static void should_allow_save_when_only_discount_to_apply_is_populated() {
        Recurrings__c recurring = buildValidRecurring('CRMFM-2 Recurring');
        recurring.Discount_to_Apply__c = 'Account';
        recurring.ManualPrice__c = null;

        Test.startTest();
        insert recurring;
        Test.stopTest();

        Assert.isNotNull(recurring.Id, 'Recurring Order should save when only Discount to Apply is populated.');
    }

    @isTest
    static void should_allow_save_when_only_manual_price_is_populated() {
        Recurrings__c recurring = buildValidRecurring('CRMFM-2 Recurring');
        recurring.Discount_to_Apply__c = null;
        recurring.ManualPrice__c = 10;

        Test.startTest();
        insert recurring;
        Test.stopTest();

        Assert.isNotNull(recurring.Id, 'Recurring Order should save when only Manual Price is populated.');
    }

    @isTest
    static void should_block_save_when_manual_price_and_discount_to_apply_are_both_blank() {
        Recurrings__c recurring = buildValidRecurring('CRMFM-2 Recurring');
        recurring.Discount_to_Apply__c = null;
        recurring.ManualPrice__c = null;

        Test.startTest();
        try {
            insert recurring;
            Assert.fail('Expected a DmlException when both Manual Price and Discount to Apply are blank.');
        } catch (DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('A Recurring Order must have either a Manual Price or a Discount to Apply'),
                'Expected the RestrictDiscountToApply error message, got: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void should_block_save_when_manual_price_and_discount_to_apply_are_both_populated() {
        Recurrings__c recurring = buildValidRecurring('CRMFM-2 Recurring');
        recurring.Discount_to_Apply__c = 'Account';
        recurring.ManualPrice__c = 10;

        Test.startTest();
        try {
            insert recurring;
            Assert.fail('Expected a DmlException when both Manual Price and Discount to Apply are populated.');
        } catch (DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('A Recurring Order must have either a Manual Price or a Discount to Apply'),
                'Expected the RestrictDiscountToApply error message, got: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void should_block_update_when_both_fields_are_cleared() {
        Recurrings__c recurring = buildValidRecurring('CRMFM-2 Recurring');
        recurring.Discount_to_Apply__c = 'Account';
        recurring.ManualPrice__c = null;
        insert recurring;

        recurring.Discount_to_Apply__c = null;

        Test.startTest();
        try {
            update recurring;
            Assert.fail('Expected a DmlException when clearing Discount to Apply leaves both fields blank.');
        } catch (DmlException ex) {
            Assert.isTrue(ex.getMessage().contains('A Recurring Order must have either a Manual Price or a Discount to Apply'),
                'Expected the RestrictDiscountToApply error message, got: ' + ex.getMessage());
        }
        Test.stopTest();
    }

    @isTest
    static void should_allow_bulk_insert_when_each_record_has_exactly_one_field_populated() {
        Id locationId = [SELECT Id FROM Account WHERE Name = 'CRMFM-2 Location Account' LIMIT 1].Id;
        Id productId = [SELECT Id FROM Product2 WHERE Name = 'CRMFM2-Prod' LIMIT 1].Id;
        Id supplierId = [SELECT Id FROM Suppliers__c WHERE Name = 'First Mile Ltd - CRMFM2' LIMIT 1].Id;
        Id facilityId = [SELECT Id FROM Facility__c WHERE Name = 'Facility - CRMFM2' LIMIT 1].Id;

        List<Recurrings__c> recurrings = new List<Recurrings__c>();
        for (Integer i = 0; i < 200; i++) {
            Recurrings__c recurring = buildRecurring(locationId, productId, supplierId, facilityId, 'Bulk_Recurring_' + i);
            if (Math.mod(i, 2) == 0) {
                recurring.Discount_to_Apply__c = 'Account';
                recurring.ManualPrice__c = null;
            } else {
                recurring.Discount_to_Apply__c = null;
                recurring.ManualPrice__c = 10;
            }
            recurrings.add(recurring);
        }

        Test.startTest();
        insert recurrings;
        Test.stopTest();

        Assert.areEqual(200, [SELECT COUNT() FROM Recurrings__c WHERE Name LIKE 'Bulk_Recurring_%'],
            'All 200 bulk Recurring Orders with exactly one populated field should save successfully.');
    }

    private static Recurrings__c buildValidRecurring(String name) {
        Id locationId = [SELECT Id FROM Account WHERE Name = 'CRMFM-2 Location Account' LIMIT 1].Id;
        Id productId = [SELECT Id FROM Product2 WHERE Name = 'CRMFM2-Prod' LIMIT 1].Id;
        Id supplierId = [SELECT Id FROM Suppliers__c WHERE Name = 'First Mile Ltd - CRMFM2' LIMIT 1].Id;
        Id facilityId = [SELECT Id FROM Facility__c WHERE Name = 'Facility - CRMFM2' LIMIT 1].Id;
        return buildRecurring(locationId, productId, supplierId, facilityId, name);
    }

    private static Recurrings__c buildRecurring(Id locationId, Id productId, Id supplierId, Id facilityId, String name) {
        return new Recurrings__c(
            Account__c = locationId,
            Active__c = false,
            First_Date__c = Date.today().addDays(1),
            Product__c = productId,
            Quantity__c = 2,
            Recur_every__c = '1',
            Rec__c = 'Month',
            Name = name,
            Type__c = 'Invoicing',
            Supplier__c = supplierId,
            Facility__c = facilityId
        );
    }
}