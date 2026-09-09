@isTest
public class UnitTest_Test
{
    public static testmethod void unittest()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        Account acc = UnitTest.testLocationTypeAccount();
        acc = UnitTest.testLocationTypeAccount();
        acc = UnitTest.testAccountTypeAccount(); 
        acc = UnitTest.testAccount();       
        Contact con = UnitTest.testcontact(acc.Id);        
        AccountContactRelation acr1 = UnitTest.testAccConRelation(acc.Id,con.Id, 'Service Contact'); 
        case cs1 = UnitTest.testcase(acc.Id,con.Id);
    }
}