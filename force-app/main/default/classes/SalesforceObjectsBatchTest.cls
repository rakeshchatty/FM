@isTest
public class SalesforceObjectsBatchTest {
   @IsTest
   static void testMethod1() {
    TestDataHelper.insertAccount();
    SalesforceObject__c obj = new SalesforceObject__c(Name = 'Account');
    INSERT obj;
    Database.executeBatch(new SalesforceObjectsBatch(), 1);
   }
}