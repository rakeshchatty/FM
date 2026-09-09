@isTest
public class WasteTransferNoteDueTest {
    
    @isTest
    static void testMethod1() {
        Account parent = new Account();
		parent.Name = 'test location2';
		parent.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		parent.Price_Book__c = Test.getStandardPricebookId();
		parent.Enqix_Dead_Live__c = 'Live';
		parent.Enqix_Date_Made_Live__c = System.today() - 1;
		parent.Has_a_central_order_point__c = true;
		insert parent;

		List<Account> accountsToInsert = new List<Account>();
        
		Account acc2 = new Account();
		acc2.Name = 'test location2';
		acc2.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
		acc2.Price_Book__c = Test.getStandardPricebookId();
		acc2.Enqix_Dead_Live__c = 'Live';
		acc2.ParentId = parent.Id;
		Date tomorrowsdate = System.today() + 1;
        acc2.Waste_transfer_note_due__c = TRUE;
		acc2.Enqix_Date_Made_Live__c = tomorrowsdate.addYears(-1); //scenario edml = today year - 1 and month == today month and day > today month
		accountsToInsert.add(acc2);
        
        insert accountsToInsert;
        
        Suppliers__c supp = new Suppliers__c();
		//supp.Name = 'test supplier';
		supp.Name = 'First Mile Ltd';
		supp.Phone_Number__c = '123456789';
		insert supp;

		Product_Category__c pc = new Product_Category__c();
		pc.Name = 'test pc';
		pc.Enqix_Id__c = 12345;
		pc.product_category_key__c = 'test pck';
		insert pc;

		Waste_Category__c wc = new Waste_Category__c();
		wc.Name = 'Cardboard Waste';
		wc.Codes__c = '12345';
		insert wc;

		Container_Type__c ct = new Container_Type__c();
		ct.Name = 'Not Sack';
		insert ct;
        
        Product2 prod = TestDataHelper.createProduct('test prod Recycling Sack', '12355321', 'Collection', pc.Id, wc.Id, ct.Id, '264');
		INSERT prod;
        
        List<Order> lstOrder = new List<Order>();

            lstOrder.add(new Order(
                AccountId = acc2.Id,
                EffectiveDate = System.today(),
                Delivery_Date__c = System.today() - 10,
                Status = 'Confirmed',
                AD_KG__c = 100,
                Recycled_KG__c = 100,
                WTE_KG__c = 100,
                Tonnes_CO2_Saved__c = 100,
                Pricebook2Id = Test.getStandardPricebookId()
            ));
        
        insert lstOrder;
        
        
        Compliance_Doc__c cdoc2 = new Compliance_Doc__c();
		cdoc2.RecordTypeId = Schema.SObjectType.Compliance_Doc__c.getRecordTypeInfosByName().get('Waste Transfer Notes').getRecordTypeId();
		cdoc2.Name = 'test cdoc2';
		cdoc2.Product__c = prod.Id;
		cdoc2.Order__c = lstOrder.get(0).Id;
		cdoc2.Account__c = acc2.Id;
		cdoc2.StartDate__c = system.today();
		cdoc2.Contractor__c = supp.Id;
		cdoc2.EndDate__c = System.today();
		cdoc2.MostRecent__c = TRUE;
		cdoc2.Generated_on_Salesforce__c = true;
		insert cdoc2;
        
        test.startTest();
        
        wasteTransferNoteDueBatch batch = new wasteTransferNoteDueBatch();
        Database.executeBatch(batch, 100);
        
        wasteTransferNoteDueSch nis = new wasteTransferNoteDueSch();
        nis.execute(null);
        
        test.stopTest();
        
    }

}