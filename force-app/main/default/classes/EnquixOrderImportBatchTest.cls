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
private class EnquixOrderImportBatchTest {
    @TestSetup
    static void dataSetup() {

        List<EnquixImportMappings__c> enquixImportMappings =
                Test.loadData(EnquixImportMappings__c.sObjectType, 'EnqixTestMappings');

        //we need four locations due to the import file template one per accounts
        List<Account> accounts = TestDataFactory.createAccounts('accounts', 4);

        insert accounts;

        //one loca per account
        List<Account> locations = TestDataFactory.createLocations(accounts, 'locations', 1);

        insert locations;

        List<String> locEnqixIds = new List<String>();
        for(Account location : locations) {

            locEnqixIds.add(location.Enqix_ID__c);
        }

        //we need four products
        List<Product2> products = TestDataFactory.createProductsForImport('Product', 4);
        insert products;

        List<String> prodEnqixIds = new List<String>();
        for(Product2 product : products) {

            prodEnqixIds.add(product.Enqix_ID__c);
        }

        List<PricebookEntry> pbEntries = TestDataFactory.createStandardPrice(products, 2.34);
        insert pbEntries;

        Enqix_Import__c enqixImport = new Enqix_Import__c();
        enqixImport.Status__c = EquixImportManager.STATUS_PENDING   ;
        enqixImport.Type__c = EquixImportManager.IMPORT_TYPE_ORDER;

        insert enqixImport;

        Attachment att = new Attachment(
                Name = 'Test',
                Body = Blob.valueOf(TestDataFactory.getOrderOrderLineImportList(locEnqixIds, prodEnqixIds)),
                ParentId = enqixImport.Id
        );

        NoTriggers__c flag = NoTriggers__c.getInstance(UserInfo.getUserId());
        flag.Flag__c = true;

        insert flag;

        insert att;

    }

    static testMethod void testBehavior() {

        Test.startTest();

        System.assert(EnquixOrderImportBatch.batchMe());

        Test.stopTest();

    }
}