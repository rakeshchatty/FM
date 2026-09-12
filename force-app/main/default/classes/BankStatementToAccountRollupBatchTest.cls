@isTest
private class BankStatementToAccountRollupBatchTest {

	@isTest
	static void test_method_one() {
		TestDataHelper.insertVat();
		Account parent = TestDataHelper.createAccount();
		INSERT parent;

		List<Bank_Statement__c> bankStatements = new List<Bank_Statement__c>();
		Bank_Statement__c bs = new Bank_Statement__c();
		bs.Transaction_Details__c = 'ZARA UK LIMITED 0000000';
		bs.Unallocated_Amount__c = 100;
		bs.Account__c = parent.Id;
		bs.Entry_Date__c = System.today();
		bs.Transaction_Type__c = 'Bank Giro Credit';
		bs.Document_name__c = 'test bss';
		bs.Receipt_Amount__c = 20;
		bankStatements.add(bs);

		Bank_Statement__c bs2 = new Bank_Statement__c();
		bs2.Transaction_Details__c = 'ZARA UK LIMITED 0000000';
		bs2.Unallocated_Amount__c = 150;
		bs2.Account__c = parent.Id;
		bs2.Entry_Date__c = System.today();
		bs2.Transaction_Type__c = 'Bank Giro Credit';
		bs2.Document_name__c = 'test bss';
		bs2.Receipt_Amount__c = 20;
		bankStatements.add(bs2);
        INSERT bankStatements;

		Test.startTest();
		new BankStatementToAccountRollupSchedular().execute(null);
		Test.stopTest();

		List<Account> accountList = [SELECT Id, TotalUnallocatedAmount__c FROM Account];
		System.debug('Total Unallocated Amount: ' + accountList[0].TotalUnallocatedAmount__c);
	}
}