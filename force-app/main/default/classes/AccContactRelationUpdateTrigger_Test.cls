@isTest
public class AccContactRelationUpdateTrigger_Test {
	public static testmethod void UnitTest(){
        Account parentAccount = TestDataHelper.createAccount();
        insert parentAccount;
        Account childAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        insert childAccount;

        Contact cont1 = new Contact();
        cont1.LastName = 'Test1';
        cont1.AccountId = childAccount.Id;
        cont1.Email = 'test1@firstmile.co.uk';
        insert cont1;
        
        Contact cont = new Contact();
        cont.LastName = 'Test Cont';
        cont.AccountId = childAccount.Id;
        cont.Email = 'test@firstmile.co.uk';
        insert cont;
        
        List<AccountContactRelation> relation = [SELECT AccountId, ContactId, Roles FROM AccountContactRelation WHERE AccountId = :childAccount.Id AND ContactId = :cont.Id];
        
        relation[0].Roles = 'Service Contact';
        
        Test.startTest();
			update relation[0];
        Test.stopTest();

		Account acc2 = [SELECT Id, 
              	Transferred_To_Enqix__c
              	FROM Account 
              	WHERE Id =: childAccount.Id
             ];        
        System.assertEquals(childAccount.Transferred_To_Enqix__c, false, 
                            	'Sale Price calculation is not working properly!');
    }
}