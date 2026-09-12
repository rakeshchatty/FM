@isTest
public class AttachmentHandler_Test {
    @isTest
    public static void afterInsertOrDeleteEvent_Test(){
        Test.startTest();
        Account parentAccount = TestDataHelper.createAccount();
        insert parentAccount;
        Account childAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        insert childAccount;
        Suppliers__c supObj =  TestDataHelper.insertSupplier('Test Supp');
        
        Order orderObj = new Order(
            AccountId = childAccount.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Status = 'draft',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Type = 'Regular',
            PO_Number__c = 'WheelieBinOrder0',
            Invoice_Created__c = false,
            Supplier__c = supObj.Id
        );
        insert orderObj;
        
        Blob bodyTest = Blob.valueOf('Test Data');
        
        Attachment attachment = new Attachment();
        attachment.ParentId = orderObj.Id;
        attachment.Name = 'Test Attachment for Parent';
        attachment.Body = bodyTest;
        insert(attachment);
        Test.stopTest();
        
    }
}