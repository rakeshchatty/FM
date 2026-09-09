@isTest
public class AccountLogoUploadController_Test{
    
    public static testmethod void MyUnitTest1(){
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        
        ApexPages.StandardController sc = new ApexPages.StandardController(locationAccount);
        
        PageReference pageRef = Page.AccountLogo;
        pageRef.getParameters().put('id', String.valueOf(locationAccount.Id));
        Test.setCurrentPage(pageRef);
        AccountLogoUploadController cls = new AccountLogoUploadController(sc);
        
        cls.file = blob.valueOf('Test');
        cls.upload();
    }
    
}