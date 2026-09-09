@isTest
private class DirectDebitControllerTest {
    
    @testSetup
    static void setup() {
        Id parentRecord = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        Account novaConta = new Account(
			Name = 'TESTE Account',
			Enqix_Payment_Method__c = 'Direct Debit',
            Payment_Account_Number__c = '123',
            Payment_Sort_Code__c = '12345678',
            CP_Account_Code__c = '12345678',
            Enqix_Id__c = '12345',
            Direct_Debit_authorised__c = true,
            recordTypeId = parentRecord,
            Direct_Debit_Authorised_Date__c = Date.newInstance(2019, 02, 01)
		);
        insert novaConta;
        Contact newCC = new Contact(
            FirstName = 'Test',
        	LastName = 'Nuno',
            AccountId = novaConta.Id,
            Email = 'test@hotmail.com',
            Contact_Role__c = 'Service Contact'
        );
        insert newCC;
        Account novaConta2 = new Account(
			Name = 'TESTE Account2',
			Enqix_Payment_Method__c = 'Direct Debit',
            Payment_Account_Number__c = '1234',
            Payment_Sort_Code__c = '12345679',
            Direct_Debit_authorised__c = true,
            recordTypeId = parentRecord,
            Direct_Debit_Authorised_Date__c = Date.newInstance(2019, 02, 01)
		);
		//insert novaConta2;
        system.debug('NOVA INVOICE' + novaConta);
        
        Invoice_Header__c header = new Invoice_Header__c(
			Name = 'TESTE header',
			Account__c = novaConta.Id,
			Salesforce__c = true,
            InvoiceFrequency__c = 'Per order',
            CreatedDate__c = Date.newInstance(2019, 02, 01),
            Query__c = False
		);
		INSERT header;
        header.AmountOutstanding__c = 2000;
        UPDATE header;

        Invoice_Header__c header2 = new Invoice_Header__c(
			Name = 'TESTE header2',
			Account__c = novaConta.Id,
            Salesforce__c = true,
			InvoiceFrequency__c = 'Per order',
            CreatedDate__c = Date.newInstance(2019, 02, 01),
            Query__c = False
		);
		INSERT header2;
        header2.AmountOutstanding__c = 2000;
        UPDATE header;

        for (Account a : [SELECT Name, Payment_Account_Number__c, Payment_Sort_Code__c, (SELECT Id, AmountOutstanding__c, ToPublish__c, Query__c, DaysOutstanding__c, Payment_Due_Date__c FROM Invoice_Headers__r) FROM Account WHERE Enqix_Payment_Method__c = 'Direct Debit']) {
            for (Invoice_Header__c h : a.Invoice_Headers__r) {
                system.debug('AmountOutstanding: '+h.AmountOutstanding__c+ ' -- ToPublish: '+h.ToPublish__c+' -- Overdue Days: '+h.DaysOutstanding__c+' -- Payment Due Date: '+h.Payment_Due_Date__c);
            }
        }
        
        Document document = new Document(Name = 'FirstMileLogo', DeveloperName = 'FirstMileLogo', Body = Blob.valueOf('Test'), folderId = UserInfo.getUserId());
        INSERT document;
    }
    
  	@isTest
    static void TestfillTable() {
        DirectDebitController.fillTable();
    }
    
    @isTest
    static void TestcreateBankStatements() {
        DirectDebitController.createBankStatements();
    }
}