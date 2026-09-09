/**
* @author Zoran Zunko
* @date 10/23/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

@IsTest
private class EnquixAccountImportBatchTest {
    @TestSetup
    static void dataSetup() {

        List<EnquixImportMappings__c> enquixImportMappings =
                Test.loadData(EnquixImportMappings__c.sObjectType, 'EnqixTestMappings');

        Enqix_Import__c enqixImport = new Enqix_Import__c();
        enqixImport.Status__c = 'Pending';
        enqixImport.Type__c = 'Accounts/Locations';

        insert enqixImport;

        Attachment att = new Attachment(
                Name = 'Test',
                Body = Blob.valueOf(String.join(TestDataFactory.accountLocationImportList, Parser.CRLF)),
                ParentId = enqixImport.Id
        );

        NoTriggers__c flag = NoTriggers__c.getInstance(UserInfo.getUserId());
        flag.Flag__c = true;

        insert flag;

        insert att;

    }

    static testMethod void testBehavior() {

        Test.startTest();

        System.assert(EnquixAccountImportBatch.batchMe());

        Test.stopTest();

        System.assert([SELECT Id FROM Account].size() != 0);

    }
}