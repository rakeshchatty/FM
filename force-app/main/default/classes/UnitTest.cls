//Test Class: UnitTest_Test
public class UnitTest
{
    public static Account testAccount()
    {
        Account acc = new Account();
        acc.Name = 'test Account';
        acc.Enqix_Dead_Live__c = 'Live';
        acc.Council__c = 'Birmingham';
        return acc;
    }
    
    public static Account testLocationTypeAccount()
    {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsActive = true and Name= 'Location' LIMIT 1];         
        //Id RecordTypeIdlocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
        Account acc = new Account();
        acc.Name = 'test Account';
        acc.RecordTypeId = rt.Id;
        acc.Council__c = 'Birmingham';
        acc.Enqix_Dead_Live__c = 'Live';
        return acc;
    }
    
    public static Account testAccountTypeAccount()
    {
        //Id RecordTypeIdlocation = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND IsActive = true and Name= 'Account' LIMIT 1];  
        Account acc = new Account();
        acc.Name = 'test Account';
        acc.RecordTypeId = rt.Id;
        acc.Enqix_Dead_Live__c = 'Live';
        acc.Council__c = 'Birmingham';
        return acc;
    }

    public static contact testcontact(Id AccountId)
    {
        Contact con = new Contact();
        con.AccountId = AccountId;
        con.Unsubscribed__c = false;
        con.FirstName = 'test';
        con.LastName = 'test';
        con.Email = 'test@de.com';
        con.FMCP_Token__c = 'test123';
        return con;
    }
    
    public static AccountContactRelation testAccConRelation(Id AccountId, Id ContactId, string Role)
    {
        AccountContactRelation acr = new AccountContactRelation(); 
        acr.AccountId = AccountId;
        acr.ContactId = ContactId; 
        acr.Roles = Role;
        return acr;
    }
    
    public static Case testcase(Id AccountId, Id ContactId)
    {
        RecordType rt = [SELECT Id FROM RecordType WHERE SObjectType = 'Case' AND IsActive = true LIMIT 1];  
        Case reccase = new Case();
        reccase.AccountId = AccountId;
        reccase.ContactId = ContactId;
        reccase.RecordTypeId = rt.Id;
        return reccase;
    }
    
    public static Sendgrid_Setting__c testsgsetting()
    {
        TestDataHelper.insertSendGridSetting();
        Sendgrid_Setting__c objsg = new Sendgrid_Setting__c();
        objsg.Name = 'IntegrationId';
        objsg.Email_Activity_EndPoint__c = 'https://api.sendgrid.com/v3/messages?limit=10';
        objsg.Integration_API_Key__c = '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';
        objsg.Location_Contact_Sendgrid_Id__c = 'bff14abf-91c6-44c9-b3d5-d2293566f3a3';
        objsg.Account_Contact_Sendgrid_Id__c = 'bff14abf-91c6-44c9-b3d5-d2293566f3a3';
        objsg.SyncToSendgrid__c = true;
        objsg.Sendgrid_From_Email__c = 'joe.allen@test.com';
        objsg.Sendgrid_From_Name__c = 'joe Allen';
        objsg.Sendgrid_ReplyTo_Email__c = 'joe.allen@test.com';
        objsg.Sendgrid_ReplyTo_Name__c = 'joe Allen';
        return objsg;
    }  
}