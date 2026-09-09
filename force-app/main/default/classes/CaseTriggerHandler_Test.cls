@isTest
public class CaseTriggerHandler_Test{

    public static testmethod void MyUnitTest(){
        
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        List<RecordType> CaseRecordTypes = new list<RecordType>();
        CaseRecordTypes = [Select Id, Name from recordType where sObjectType = 'Case' and isActive = true];
        
        list<Case_Types__c> Setting = new list<Case_Types__c>();
        
        Case_Types__c cs = new Case_Types__c();
        cs.Name = 'CS1';
        cs.Case_Type__c = 'Operational Complaint';
        cs.Case_Record_Type_Name__c = 'Operations';
        setting.add(cs);
        
        Case_Types__c cs2 = new Case_Types__c();
        cs2.Name = 'CS2';
        cs2.Case_Type__c = 'Health & Safety';
        cs2.Case_Record_Type_Name__c = 'Health & Safety';
        setting.add(cs2);
        
        insert setting;
        
        List <Case> cases = new List<Case>();
        
        Case caseObj = new Case(
        AccountId = locationAccount.Id,
        Ops_Issue_Type__c = 'Excess Waste',
        Status = 'Working',
        Origin = 'Phone',
        Type = 'Operational Complaint');
        
        cases.add(caseObj);
        
        Case caseObj1 = new Case(
        AccountId = locationAccount.Id,
        Ops_Issue_Type__c = 'Contamination',
        Status = 'Working',
        Origin = 'Phone', 
        Type = 'Operational Test');
        
        cases.add(caseObj1);
        
        //insert cases;
        
        CaseTriggerHandler test = new CaseTriggerHandler();
        test.UpdateContaminationField(cases);
        test.UpdateCaseRecordType(cases);   
    }
    
	public static testmethod void MyUnitTest1(){
        
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
        INSERT locationAccount;
        
        List <Case> cases = new List<Case>();
        
        Case caseObj = new Case(
        AccountId = locationAccount.Id,
        Ops_Issue_Type__c = 'Excess Waste',
        Status = 'Working',
        Origin = 'Phone',
        Type = 'Operational Complaint');
        
        cases.add(caseObj);
        
        Case caseObj1 = new Case(
        AccountId = locationAccount.Id,
        Ops_Issue_Type__c = 'Contamination',
        Status = 'Working',
        Origin = 'Phone', 
        Type = 'Operational Test');
        
        cases.add(caseObj1);
        
        insert cases;
}
}