/** 
(c) 2018 Nexell GmbH / Rolling-Space
Developed by Nexell GmbH, Zug (Switzerland) / Rolling-Space, Braga (Portugal)
@date Date of creation mm.yyyy 
@author Name of initial developer 

@description Initial PT or Case number + description of what the class does 

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields 
*/
@isTest
private class BankStatementsTriggerInactive_Test {
	
	@isTest static void test_method_one() {
		Account a = new Account();
		a.Name = 'test account';
		a.BACS_Account_Number__c = 'D 000000';
		a.BACS_Sort_Code__c = 'UK LIMIT';
		a.Enqix_Id__c = '12345y';
		a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
		insert a;

		Bank_Statement__c bs = new Bank_Statement__c();
		bs.Transaction_Details__c = 'ZARA UK LIMITED 0000000';
		bs.Unallocated_Amount__c = 20;
		bs.Account__c = a.Id;
		bs.Entry_Date__c = System.today();
		bs.Transaction_Type__c = 'Bank Giro Credit';
		bs.Document_name__c = 'test bss';
		bs.Receipt_Amount__c = 20;
		insert bs;
	}
	
}