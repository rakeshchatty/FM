/** 
(c) 2018 Xpand IT
Developed by Xpand IT, Braga (Portugal)
@date Date of creation 11.2018 
@author Bruno Mendes 

@description 1034 - Batch job to create Bank Statements for Direct Debit functionality 

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields 
XX.05.2019 JIRA 1578 -> Improve email to customer functionality
*/
global class DirectDebitBatch implements Database.Batchable < sObject > , Database.Stateful {
    
    global decimal amountAccount;
    global string runSucceeded;
    global String query;
    global List < AccountAmount > accounts;
    global String errors;
    global List<Bank_Statement__c> finalBankStatementList;
    global Map < AccountContactRelation, Id > financeContas;

    public class AccountAmount {
        
        public String company {
            get;
            set;
        }        
        public Id accountId {
            get;
            set;
        }
        public String accountName {
            get;
            set;
        }
        public string sortCode {
            get;
            set;
        }
        public String accountNumber {
            get;
            set;
        }
        public Decimal amount {
            get;
            set;
        }
        public String error { 
            get;
            set;
        }
        public string ddBeforeCode {
            get; 
            set;
        }
        
        public AccountAmount(string company, Id accountId, String accountName, String sortCode, String accountNumber, Decimal amount, string ddBeforeCode) {
            this.company = company;
            this.accountId = accountId;
            this.accountName = accountName;
            this.sortCode = sortCode;
            this.accountNumber = accountNumber;
            this.amount = amount;
            this.ddBeforeCode = ddBeforeCode;
        }
    }
    
    global DirectDebitBatch() {
        accounts = new List < AccountAmount > ();
        errors = '';
        finalBankStatementList = new List<Bank_Statement__c>();
        /* Bruno - JIRA 1431 -> Added Status != Query to the filter. Removed OverdueDays  */
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        query = 'SELECT Name, dd_account_number__c, dd_sort_code__c, Paid_by_DD_Before__c, (SELECT Id, AmountOutstanding__c FROM Invoice_Headers__r WHERE Payment_Due_Date__c <= TODAY AND AmountOutstanding__c != 0 AND AmountOutstanding__c != null AND Query__c = false AND Status__c != \'Query\') FROM Account WHERE Enqix_Payment_Method__c = \'Direct Debit\' AND Direct_Debit_authorised__c = true AND DAY_ONLY(Direct_Debit_Authorised_Date__c) < TODAY AND Id IN (SELECT Account__c FROM Invoice_Header__c WHERE Account__r.Enqix_Payment_Method__c = \'Direct Debit\' AND Account__r.Direct_Debit_authorised__c = true AND DAY_ONLY(Account__r.Direct_Debit_Authorised_Date__c) < TODAY AND Payment_Due_Date__c <= TODAY AND AmountOutstanding__c != 0 AND AmountOutstanding__c != null AND Query__c = false AND Status__c != \'Query\') ORDER BY Name';
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<Account> targetAccounts) {
        List < Bank_Statement__c > bankStatementsToCreate = new List < Bank_Statement__c > ();
        List < PaymentAllocation__c > paymentAllocationsToCreate = new List < PaymentAllocation__c > ();
        Map<Id, Invoice_Header__c> invoiceHeadersToUpdateMap = new Map<Id, Invoice_Header__c>();
        Map<Id, Account> accountInvoicesToBePaid = new Map<Id, Account>();
        
        for (Account a : targetAccounts) {
            string ddBeforeCode = '0';
            if(a.Paid_by_DD_Before__c == true){
                ddBeforeCode = '17';
            }else if(a.Paid_by_DD_Before__c == false){
                ddBeforeCode = '01';
            }
            
            string company = 'FirstMile';
            
            Decimal amount = 0;
            for (Invoice_Header__c i: a.Invoice_Headers__r) {
                amount += i.AmountOutstanding__c.setscale(2);
            }
            /* Bruno - Jira 1430 -> Checked if the amount is less than zero and ignored those accounts */ 
            if (amount <= 0) {
                continue;
            }

            Bank_Statement__c bs = new Bank_Statement__c();
            bs.Account__c = a.Id;
            bs.Entry_Date__c = System.today();
            bs.Transaction_Details__c = a.Name + ' Direct Debit Payment';
            bs.Transaction_Type__c = 'Direct Debit';
            bs.Document_name__c = 'Direct Debit Remittance ' + System.today();
            bs.IsDirectDebit__c = True;
            bs.Customer_Reference__c = a.Name + bs.Entry_Date__c + ' DD Remittance';
            bankStatementsToCreate.add(bs);

            AccountAmount aa = new AccountAmount(company, a.Id, a.Name, a.dd_sort_code__c, a.dd_account_number__c, amount, ddBeforeCode);
            accounts.add(aa);
            accountInvoicesToBePaid.put(a.Id, a); 
        }

        Database.SaveResult[] resultsBS = Database.insert(bankStatementsToCreate, false);
        LogRegister.createLogsUpsert(resultsBS, bankStatementsToCreate, 'DirectDebitBatch', 'Insert', 'Bank_Statement__c', 'Account__c');
        for (Integer idx = 0; idx < resultsBS.size(); idx++) {
            if (!resultsBS[idx].isSuccess()) {
                for (Database.Error err: resultsBS[idx].getErrors()) {
                    errors += 'Account where the error occurred: ' + bankStatementsToCreate[idx].Account__c + ' on Bank Statement creation --- The following error has occurred - ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields() + '\n';
                }
                for (Integer i = 0; i < accounts.size(); i++) {
                    if (accounts[i].accountId == bankStatementsToCreate[idx].Account__c) {
                        accounts.remove(i);
                    }
                }
            }
        }
        
        for (Bank_Statement__c bs: bankStatementsToCreate) {
            if (bs.Id == null) continue;

            Account account = accountInvoicesToBePaid.get(bs.Account__c);
            for (Invoice_Header__c i : account.Invoice_Headers__r) {
                PaymentAllocation__c pa = new PaymentAllocation__c();
                pa.InvoiceId__c = i.Id;
                pa.BankstatementId__c = bs.Id;
                pa.Account__c = bs.Account__c;
                pa.AllocatedAmount__c = i.AmountOutstanding__c.setscale(2);
                pa.IsDirectDebit__c = true;
                paymentAllocationsToCreate.add(pa);
                /* Bruno - Jira 1426 -> Process was only updating the amountoutstanding of one invoice header, which was wrong */
                Invoice_Header__c ih = new Invoice_Header__c();
                ih.Id = i.Id;
                ih.AmountOutstanding__c = 0;
                invoiceHeadersToUpdateMap.put(ih.Id, ih);
            }
        }
        
        Database.SaveResult[] resultsPA = Database.insert(paymentAllocationsToCreate, false);   
        LogRegister.createLogsUpsert(resultsPA, paymentAllocationsToCreate, 'DirectDebitBatch', 'Insert', 'PaymentAllocation__c', 'Account__c');
        for (Integer idx = 0; idx < resultsPA.size(); idx++) {
            if (!resultsPA[idx].isSuccess()) {
                for (Database.Error err: resultsPA[idx].getErrors()) {
                    errors += 'Account where the error occurred: ' + paymentAllocationsToCreate[idx].Account__c + ' on Bank Statement creation --- The following error has occurred - ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields() + '\n';
                    PaymentAllocation__c pa = paymentAllocationsToCreate[idx];
                    invoiceHeadersToUpdateMap.remove(pa.InvoiceId__c);
                }
                for (Integer i = 0; i < accounts.size(); i++) {
                    if (accounts[i].accountId == paymentAllocationsToCreate[idx].Account__c) {
                        accounts.remove(i);
                    }
                }
            }
        }     
        
        Database.SaveResult[] resultsIH = Database.update(invoiceHeadersToUpdateMap.values(), false);
        LogRegister.createLogsUpsert(resultsIH, invoiceHeadersToUpdateMap.values(), 'DirectDebitBatch', 'Update', 'Invoice_Header__c', 'Account__c');
        for (Integer idx = 0; idx < resultsIH.size(); idx++) {
            if (!resultsIH[idx].isSuccess()) {
                for (Database.Error err: resultsIH[idx].getErrors()) {
                    errors += 'Account where the error occurred: ' + invoiceHeadersToUpdateMap.values()[idx].Account__c + ' on Bank Statement creation --- The following error has occurred - ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields() + '\n';
                }
                for (Integer i = 0; i < accounts.size(); i++) {
                    if (accounts[i].accountId == invoiceHeadersToUpdateMap.values()[idx].Account__c) {
                        accounts.remove(i);
                    }
                }
            }
        }
        
        //BRUNO - added this code because if an error happens when creating a payment allocation and
        //		  a bank statement is created without any payment allocation, it should be deleted
        Set<Id> bsIds = new Set<Id>();
        for (Bank_Statement__c bs : bankStatementsToCreate) {
            bsIds.add(bs.Id);
        }
        
        List<PaymentAllocation__c> payments = [SELECT Id, BankstatementId__c FROM PaymentAllocation__c WHERE BankstatementId__c IN :bsIds];
        List<Bank_Statement__c> bsToDelete = new List<Bank_Statement__c>();
        Set<Id> existingBS = new Set<Id>();
        for (PaymentAllocation__c pa : payments) {
            existingBS.add(pa.BankstatementId__c);
        }
        List<Bank_Statement__c> bankStatementsToUpdate = new List<Bank_Statement__c>();
        for (Bank_Statement__c bs : bankStatementsToCreate) {
            if (!existingBS.contains(bs.Id) && bs.Id != null) {
                bsToDelete.add(bs);
            }
        }
        if (bsToDelete.size() > 0) {
            Database.DeleteResult[] resultsBsDel = Database.delete(bsToDelete, false);
            LogRegister.createLogs(resultsBsDel, bsToDelete, 'DirectDebitBatch', 'Delete', 'Bank_Statement__c', 'Account__c');
        }  
        
        List <Account> acc = new list <Account>();
        for (AccountAmount aAm: accounts) {           
            Account ac = new Account();            
            ac.id = aAm.accountId;            
            ac.Paid_by_DD_Before__c = true;
            acc.add(ac);
        }
        UPDATE acc;
    }
    
    global void finish(Database.BatchableContext BC) {
        Database.executebatch(new DirectDebitEmailRemittanceBatch(), 50);
        
        DateTime todaysDate = DateTime.now();
        string sTodaysDate = todaysDate.formatGMT('yyyy-MM-dd') + 'T' + todaysDate.formatGMT('HH:mm:ss.SSS') + 'Z';
        String subject = 'Direct Debit';
        String body = 'You will find attached to this email a CSV file containing the results of the Direct Debit Remittance </br>';
        if (String.isNotBlank(errors)) {
            body += errors;
        }
        String finalstr = '\n';
        String attName = 'DirectDebit_'+sTodaysDate+'.csv';
        
        // get accounts
        for (AccountAmount a: accounts) {
            string recordString = '"' + a.accountName + '","' + a.company + '","' + a.sortCode + '","' + a.accountNumber + '","' + a.amount + '","' + a.ddBeforeCode + '"\n';
            finalstr = recordString + finalstr;
        }
        String finalstrTrimmed = finalstr.trim();
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        if (accounts.size() > 0) {
            // Create the email attachment    
            Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
            efa.setFileName(attName);
            efa.setBody(Blob.valueOf(finalstrTrimmed));

            // Attach file using setFileAttachments function
            email.setFileAttachments(new Messaging.EmailFileAttachment[] {  efa });
        }
        
        // Set the paramaters to the email object
        email.setSubject(subject);
        email.setUseSignature(false);
        
        // Create the email Address
        email.setToAddresses(new String[] {'accounts@thefirstmile.co.uk'});
        email.setHtmlBody(body);
        
        // Sends the email
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
        }
    }
}