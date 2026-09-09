@isTest
public class OpportunityTrigger_Test{

    public static testmethod void UnitTest(){
        
        Account acc = new Account();
        acc.Name = 'Test Acc';
        acc.Enqix_Dead_Live__c = 'Pending';
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        insert acc;
        
        Opportunity opp = new Opportunity();
        opp.Name = 'Test Opp';
        opp.StageName = 'Unqualified';
        opp.CloseDate = date.today().addDays(20);
        opp.AccountId = acc.Id;
        opp.Services__c = 'Secure Shredding	';
        insert opp;
        
        opp.StageName = 'Handed Over';
        update opp;
        
        
    }
}