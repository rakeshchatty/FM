@isTest
public with sharing class SetLiveControllerTest {
	
    @isTest
    public static void testDeadLive(){
        Id pricebookId = Test.getStandardPricebookId();
          
		Account acc = new Account();
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        acc.Name = 'parentacc';
        acc.BillingStreet = 'test street';
        acc.BillingCity = 'test city'; 
        acc.Transferred_To_Enqix__c = false;
        acc.Price_Book__c = pricebookId;
        acc.Enqix_Start_Date__c = null;
        insert acc;
        
		Account acc2 = TestDataHelper.createLocation(acc.Id, null);
        acc2.Name = 'child1';
        acc2.BillingStreet = 'test streets';
        acc2.BillingCity = 'test cityy';  
        acc2.Transferred_To_Enqix__c = false;
        insert acc2;
        
		List <Contact> contactList = new List <Contact>();
        Contact c = new Contact();
        c.LastName = 'asdsa';
        c.AccountId = acc.Id;
        c.Contact_Role__c = 'Finance Contact';
        c.Email = 'email2@email.com';
        contactList.add(c);

		Contact c2 = new Contact();
        c2.LastName = 'asdsa';
        c2.AccountId = acc2.Id;
        c2.Contact_Role__c = 'Finance Contact';
        c2.Email = 'email1@email.com';
        contactList.add(c2);
       
        Contact c3 = new Contact();
        c3.LastName = 'test';
        c3.AccountId = acc2.Id;
        c3.Contact_Role__c = 'Finance Contact';
        c3.Email = 'test@firstmile.co.uk';
        contactList.add(c3);
        insert contactList;
        
        AccountContactRelation acr = [select Id, Roles from AccountContactRelation where AccountId = :acc.Id and ContactId = :c.Id limit 1];
        acr.Roles = 'Finance Contact; Service Contact';
        update acr;

		AccountContactRelation acr2 = [select Id, Roles from AccountContactRelation where AccountId = :acc2.Id and ContactId = :c2.Id limit 1];
        acr2.Roles = 'Service Contact';
        update acr2;
        
        Account_Discount__c ad = new Account_Discount__c(
            Account__c = acc.Id,
            DiscountSupStartDate__c = system.today()
        );
		insert ad;
        
        Order Ord1 = new Order(
            AccountId = acc2.id,
            EffectiveDate = System.today(),
            Delivery_Date__c = System.today(),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = PricebookId
        );
        insert ord1;
        
		acc2.Enqix_Start_Date__c = null;
		update acc2;        
		
        //Test account with orders related
        SetLiveController.setLiveCtrl(acc2.Id);
        
        delete Ord1;
        acc2.Enqix_Dead_Live__c = 'Live';
        update acc2;
        
        //Test account with no orders related
        SetLiveController.setLiveCtrl(acc2.Id);
        
        test.startTest();
        acc2.Transferred_To_Enqix__c = true;
        update acc2;
        
        //Test account where the Parent has Transferred_To_Enqix__c = False
        SetLiveController.setLiveCtrl(acc2.Id);
        test.stopTest();
    }

}