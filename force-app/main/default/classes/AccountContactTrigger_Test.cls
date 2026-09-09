@isTest
public class AccountContactTrigger_Test{

    public static testmethod void UnitTest(){
        Account parentAccount = TestDataHelper.createAccount();
        insert parentAccount;
        Account childAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        insert childAccount;
        
        Contact cont = new Contact();
        cont.LastName = 'Test Cont';
        cont.AccountId = childAccount.Id;
        cont.Email = 'test@firstmile.co.uk';
        insert cont;
    }
}