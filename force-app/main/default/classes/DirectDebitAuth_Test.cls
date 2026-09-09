@isTest
public class DirectDebitAuth_Test {
    
    @testSetup
    static void setup() {
        Id parentRecord = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account newAccount = new Account(
			Name = 'Test Account',
			Enqix_Payment_Method__c = 'Direct Debit',
            dd_account_number__c = '123',
            dd_sort_code__c = '12345678',
            Direct_Debit_authorised__c = false,
            Direct_Debit_Details_Entry_Date__c = system.now(),
            recordTypeId = parentRecord
		);
        insert newAccount;
    }
    
  	@isTest
    static void TestfillTable(){
        
        DirectDebitAuthController.getAuthorizedAccounts();
        
    }
    
    @isTest
    static void TestcreateBankStatements(){
        
      
        DirectDebitAuthController.generateCSV();
    }
}