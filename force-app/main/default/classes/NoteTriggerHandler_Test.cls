@isTest
public class NoteTriggerHandler_Test {
@isTest
    public static void afterInsertOrDeleteEvent_Test(){
        Test.startTest();
        Account parentAccount = TestDataHelper.createAccount();
        insert parentAccount;
        Account childAccount = TestDataHelper.createLocation(parentAccount.Id, null);
        insert childAccount;
        
        Suppliers__c supObj = new Suppliers__c();
        supObj.Name = 'Test Supp';
        supObj.Phone_Number__c = '1234567898';
        INSERT supObj;
        
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
        
        Note noteObj = new Note();
        noteObj.title = 'Test Note';
        noteObj.Body = 'Test Body';
        noteObj.ParentId = orderObj.Id;
        INSERT noteObj;
        Test.stopTest();
    }
}