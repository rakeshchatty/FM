@isTest
public class getResultWS_Test {
    public static testmethod void UnitTest(){
        Account acc = TestDataHelper.insertAccount();
        getResultWS.getResult('Select id from Account');
    }
}