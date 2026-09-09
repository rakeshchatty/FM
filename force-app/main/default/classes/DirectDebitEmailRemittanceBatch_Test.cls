@isTest
public class DirectDebitEmailRemittanceBatch_Test {

    @testSetup
    public static void insertTestData() {
        Document document = new Document(Name = 'FirstMileLogo', DeveloperName = 'FirstMileLogo', Body = Blob.valueOf('Test'), folderId = UserInfo.getUserId());
        INSERT document;
    }

    @isTest 
    public static void testDirectDebitEmailRemittance()
    {
        
        Account account = new Account();
        account.Name = 'Xpand IT';
        account.recordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        account.Enqix_Payment_Method__c = 'Direct Debit';
        account.Payment_Account_Number__c = '1234';
        account.Payment_Sort_Code__c = '12345679';
        account.Direct_Debit_authorised__c = true;
        account.Direct_Debit_Authorised_Date__c = Date.newInstance(2019, 02, 01);
        account.dd_account_number__c = '12345678';
        account.dd_sort_code__c = '';
        account.Paid_by_DD_Before__c = true;
        insert account;
        
        Contact contact = new Contact(
            FirstName = 'Support',
        	LastName = 'Xpand IT',
            AccountId = account.Id,
            Email = 'joao.gomes@xpand-it.com',
            Contact_Role__c = 'Finance Contact'
        );
        insert contact;

        AccountContactRelation acr = [SELECT Id FROM AccountContactRelation WHERE AccountId = :account.Id];
        acr.Roles = 'Other;Finance Contact;Service Contact';
        UPDATE acr;

        Invoice_Header__c header1 = new Invoice_Header__c(
            Name = 'Test header',
            Account__c = account.Id,
            Salesforce__c = true,
            InvoiceFrequency__c = 'Per order',
            CreatedDate__c = Date.newInstance(2019, 02, 01),
            Query__c = False,
            AmountOutstanding__c = 2000,
            Status__c = 'Invoiced'
        );
        insert header1;

        Bank_Statement__c bs1 = new Bank_Statement__c();
        bs1.Account__c = account.Id;
        bs1.Entry_Date__c = System.today();
        bs1.Transaction_Details__c = account.Name + ' Direct Debit Payment';
        bs1.Transaction_Type__c = 'Direct Debit';
        bs1.Document_name__c = 'Direct Debit Remittance ' + System.today();
        bs1.IsDirectDebit__c = True;
        bs1.Customer_Reference__c = account.Name + bs1.Entry_Date__c + ' DD Remittance';
        insert bs1;

        PaymentAllocation__c payment1 = new PaymentAllocation__c();
        payment1.Account__c = bs1.Account__c;
        payment1.InvoiceId__c = header1.Id;
        payment1.BankstatementId__c = bs1.Id;
        payment1.AllocatedAmount__c = header1.AmountOutstanding__c;
        payment1.IsDirectDebit__c = true;
        insert payment1;
        
        Invoice_Header__c header2 = new Invoice_Header__c(
            Name = 'Test header',
            Account__c = account.Id,
            Salesforce__c = true,
            InvoiceFrequency__c = 'Per order',
            CreatedDate__c = Date.newInstance(2019, 02, 01),
            Query__c = False,
            AmountOutstanding__c = 2000,
            Status__c = 'Invoiced'
        );
        insert header2;

        Bank_Statement__c bs2 = new Bank_Statement__c();
        bs2.Account__c = account.Id;
        bs2.Entry_Date__c = System.today();
        bs2.Transaction_Details__c = account.Name + ' Direct Debit Payment';
        bs2.Transaction_Type__c = 'Direct Debit';
        bs2.Document_name__c = 'Direct Debit Remittance ' + System.today();
        bs2.IsDirectDebit__c = True;
        bs2.Customer_Reference__c = account.Name + bs2.Entry_Date__c + ' DD Remittance';
        insert bs2;

        PaymentAllocation__c payment2 = new PaymentAllocation__c();
        payment2.Account__c = bs2.Account__c;
        payment2.InvoiceId__c = header2.Id;
        payment2.BankstatementId__c = bs2.Id;
        payment2.AllocatedAmount__c = header2.AmountOutstanding__c;
        payment2.IsDirectDebit__c = true;
        insert payment2;

        Test.StartTest();                        
        DirectDebitEmailRemittanceBatch ddCustomerEmail = new DirectDebitEmailRemittanceBatch();
        Database.executebatch(ddCustomerEmail, 50);
        Test.StopTest();
    }
}