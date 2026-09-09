@isTest
public class Test_RelatedAccountsController {
    public static testMethod void testChildAccounts(){
        Account parentAcc = TestDataHelper.insertAccount();
        
        Account childAcc = TestDataHelper.insertLocation(parentAcc.Id, null);
        
        List<Account> accounts = RelatedAccountsController.getChildAccounts(parentAcc.Id);
        System.assert(accounts.size() == 1);
    }
}