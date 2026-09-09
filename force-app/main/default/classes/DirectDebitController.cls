global with sharing class DirectDebitController {
    
    public class AccountAmount {
        @AuraEnabled
        public String company {get;set;}
        @AuraEnabled
        public Id accountId {get; set;}
        @AuraEnabled
        public String accountName {get; set;}
        @AuraEnabled
        public string sortCode {get; set;}
        @AuraEnabled
        public String accountNumber {get; set;}
        @AuraEnabled
        public Decimal amount {get; set;} 
        @AuraEnabled
        public String decimalsPlaces {get; set;} 
        @AuraEnabled
        public List<Invoice_Header__c> invoicesToBePaid {get; set;}
        @AuraEnabled
        public decimal ddCode {get; set;}
        
        public AccountAmount(string company, Id accountId, String accountName, String sortCode, String accountNumber, Decimal amount, String decimalsPlaces, List<Invoice_Header__c> invoicesToBePaid, decimal ddCode) {
            
            this.company = company;
            this.accountId = accountId;            
            this.accountName = accountName;
            this.sortCode = sortCode;
            this.accountNumber = accountNumber;
            this.amount = amount;
            this.decimalsPlaces = decimalsPlaces;
            this.invoicesToBePaid = invoicesToBePaid;
            this.ddCode = ddCode;
            
        }
    }
    
    @AuraEnabled
    public static List<AccountAmount> fillTable() {
        List<AccountAmount> accounts = new List<AccountAmount>();
        /* Nuno - Jira 1454 -> Added a filter to the query -- Direct Debit Authorised = TRUE*/
        DateTime dt = DateTime.now() - 10;
        List < Account > accountsAndAmounts = [SELECT Name, dd_account_number__c, dd_sort_code__c, Paid_by_DD_Before__c, (SELECT Id, InvoiceNo__c, AmountOutstanding__c FROM Invoice_Headers__r WHERE AmountOutstanding__c != 0 AND AmountOutstanding__c != null AND Query__c = false AND Status__c != 'Query' AND Payment_Due_Date__c <= TODAY ) FROM Account WHERE Enqix_Payment_Method__c = 'Direct Debit' AND Direct_Debit_authorised__c = true AND Direct_Debit_Authorised_Date__c <= :dt AND Id IN(SELECT Account__c FROM Invoice_Header__c WHERE AmountOutstanding__c != 0 AND AmountOutstanding__c != null AND Query__c = false AND Status__c != 'Query' AND Payment_Due_Date__c <= TODAY) order by Name];
        Integer numberOfAccounts = Database.countQuery('SELECT COUNT() FROM Account WHERE Enqix_Payment_Method__c = \'Direct Debit\' AND Direct_Debit_authorised__c = true AND Id IN(SELECT Account__c FROM Invoice_Header__c WHERE AmountOutstanding__c != 0 AND AmountOutstanding__c != null AND Query__c = false AND Status__c != \'Query\' AND Payment_Due_Date__c <= TODAY)');
        system.debug(numberOfAccounts);
        for (Account a : accountsAndAmounts) {
            List<Invoice_Header__c> invoices = new List<Invoice_Header__c>();
            string company = 'FirstMile';
            decimal ddCode = 0;
            Decimal amount = 0; 
            String decimalsPlaces = '';
            for (Invoice_Header__c i : a.Invoice_Headers__r) {
                system.debug(i.AmountOutstanding__c);
                amount += i.AmountOutstanding__c.setscale(2);                
                invoices.add(i);               
            }
            /* Bruno - Jira 1430 -> Checked if the amount is greater than zero, as the process only wants those accounts */
            if (amount > 0) {
                AccountAmount aa = new AccountAmount(company, a.Id, a.Name, a.dd_sort_code__c, a.dd_account_number__c, amount, decimalsPlaces, invoices, ddCode);
                accounts.add(aa);
            } 
        }
        return accounts;
    }
    
    @AuraEnabled
    public static String createBankStatements() {
        Database.executebatch(new DirectDebitBatch(), 50);
        return 'Direct debits will now be processed, an email will be sent when they are finished.';
    }
}