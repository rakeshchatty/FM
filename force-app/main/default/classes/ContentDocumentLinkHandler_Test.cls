@isTest
public class ContentDocumentLinkHandler_Test {
    @isTest
    private static void insertAttachmentHandler_test(){
        Test.startTest();
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
        
        Order orderObj = new Order(
            AccountId = locationAccount.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'draft',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Invoice_Created__c = false,
            Supplier__c = supplier.Id
        );
        insert orderObj;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Test picture'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId=orderObj.id;
        contentlink.contentdocumentid=[select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlink.ShareType = 'I';
        contentlink.Visibility = 'AllUsers';         
        insert contentlink;
        ContentDocument contentDoc = [Select id from contentdocument where id=:contentlink.ContentDocumentId];
        delete contentDoc;
        Test.stopTest();
    }
}