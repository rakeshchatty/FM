@isTest
public class Test_AccountSearchController 
{
    public testMethod static void Test1()
    {
        AccountSearchController  acs = new AccountSearchController ();
        acs.PostCode = 'sss';
        acs.SearchAccount();
    }
}