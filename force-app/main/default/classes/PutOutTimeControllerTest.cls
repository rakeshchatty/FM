@isTest
public class PutOutTimeControllerTest {

    @isTest
    static void testMethod1() {
        Account account = TestDataHelper.createAccount();
        account.Street_Name__c = 'Wells Street';
        account.BillingPostalCode = 'L1 8JQ';
        INSERT account;
        Test.setMock(HttpCalloutMock.class, new DoogalTest.RestMock('L1	51.6154	-0.178479'));

        Region__c region = new Region__c();
        region.Name = 'Test 1';
        INSERT region;

        Put_Out_Time__c popOutTime = new Put_Out_Time__c();
        popOutTime.Street_Name__c = 'Wells Street'; 
        popOutTime.Put_Out_Time__c = '05:30';
        popOutTime.Postcode__c = region.Id;
        INSERT popOutTime;

        PutOutTimeController.getRelevantPutOutTimes(account.Id);
    }
}