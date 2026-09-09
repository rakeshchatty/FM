/********************************************************************************************
Create Date: 17/07/2017
By: Zachary Stevens
TestClass for MassUpdateCaseController
********************************************************************************************/
@isTest
public class Test_MassUpdateCaseController {
    public static testMethod void testCaseType(){
        LIST<Case> selectedCases = new LIST<Case>();
        Case c = new Case();
        c.Type = 'Test';
        selectedCases.add(c);
        insert selectedCases;
        
        Test.StartTest();
        ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(selectedCases);
        ctrl.setSelected(selectedCases);
        MassUpdateCaseController ext = new MassUpdateCaseController(ctrl);
        ext.cse.user_hidden__c = userinfo.GetUserId();
        ext.updateCaseOwner();
        Test.StopTest();
    }
    
    public static testMethod void testCaseStatus(){
        LIST<Case> selectedCases = new LIST<Case>();
        Case c = new Case();
        c.Status = 'Test';
        selectedCases.add(c);
        insert selectedCases;
        
        
        Test.StartTest();
        ApexPages.StandardSetController ctrl = new ApexPages.StandardSetController(selectedCases);
        ctrl.setSelected(selectedCases);
        MassUpdateCaseController ext = new MassUpdateCaseController(ctrl);
        ext.cse.Status = 'New'; 
        ext.updateCaseStatus();
        System.assertEquals([SELECT Id, Status FROM Case WHERE Id = :selectedCases[0].Id].Status,'New');
        Test.StopTest();
    }
}