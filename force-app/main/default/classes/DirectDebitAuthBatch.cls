/*
(c) 2018 Xpand IT
Developed by Xpand IT (Portugal)

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
12.03.2019 [JIRA 1445] - Inicial Version
13.03.2019 [JIRA 1445] - mod1: Change payment Account and sort fields on query to direct debit payment and sort
*/
global class DirectDebitAuthBatch implements Database.Batchable < sObject > , Database.Stateful {
    
    global String query;
    global List < authorizedAccount > accounts;
    global String errors;
    
    Public class authorizedAccount {
        public string accountName{
            get;
            set;
        }
        public string company {
            get;
            set;
        }
        public string sortCode {
            get;
            set;
        }
        public string accountNumber{
            get;
            set;
        }
        public string amount{
            get;
            set;
        }
        public string code{
            get;
            set;
        }
        
        public authorizedAccount(string accountName, string company, String sortCode, string accountNumber, string amount, String code) {
            
            this.accountName = accountName;
            this.company = company;
            this.sortCode = sortCode;
            this.accountNumber = accountNumber;
            this.amount = amount;
            this.code = code;
        }
    }
    
    global DirectDebitAuthBatch(){
        accounts = new List <authorizedAccount>();
        errors = '';
        // 13.03.2019 [JIRA 1445]
        query = 'SELECT Name, dd_account_number__c, Direct_Debit_Authorised_Date__c, Direct_Debit_authorised__c, dd_sort_code__c from Account where Enqix_Payment_Method__c = \'Direct Debit\' AND Direct_Debit_Details_Entry_Date__c != null AND Direct_Debit_authorised__c = false order by Name';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List <Sobject> scope){
        List <Account> accountsToUpdate = new List <Account>();
        
        system.debug(scope); 
        for (SObject s: scope) {
            
            Account a = (Account) s;
            
            a.Direct_Debit_authorised__c = true;
			a.Direct_Debit_Authorised_Date__c = system.now();
            
            accountsToUpdate.add(a);
            
            string amount = '0';
            string company = 'FirstMile';
            string code = '0N';            
            authorizedAccount aa = new authorizedAccount(a.Name, company, a.dd_sort_code__c, a.dd_account_number__c, amount, code);
            accounts.add(aa);
        }
        update accountsToUpdate;
    }
    
    global void finish(Database.BatchableContext BC) {
        String subject = 'Direct Debit Authorization';
        String body = 'You will find attached to this email a CSV file containing the results of the Direct Debit Authorization </br>';
        if (String.isNotBlank(errors)) {
            body += errors;
        }
        String finalstr = '\n';
        DateTime todaysDate = DateTime.now();
        string sTodaysDate = todaysDate.formatGMT('yyyy-MM-dd') + 'T' + todaysDate.formatGMT('HH:mm:ss.SSS') + 'Z';
        String attName = 'DirectDebitAuth_'+sTodaysDate+'.csv';
        
        // get accounts
        system.debug(accounts.size());
        for (authorizedAccount a: accounts) {
            string recordString = '"' + a.accountName + '","' + a.Company + '","' + a.sortCode + '","' + a.accountNumber + '","' + a.amount + '","' + a.code + '"\n';
            finalstr = recordString + finalstr;
        }
        String finalstrTrimmed = finalstr.trim();
        // Define the email
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        
        // Create the email attachment    
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(attName);
        efa.setBody(Blob.valueOf(finalstrTrimmed));
        
        // Set the paramaters to the email object
        email.setSubject(subject);
        
        // Create the email Address
        email.setToAddresses(new String[] {
            'integration@thefirstmile.co.uk','accounts@thefirstmile.co.uk'
                });
        email.setHtmlBody(body);
        
        // Attach file using setFileAttachments function
        email.setFileAttachments(new Messaging.EmailFileAttachment[] {
            efa
                });
        
        // Sends the email
        if (!Test.isRunningTest()) {
            Messaging.SendEmailResult[] r =
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {
                    email
                        });
        }       
    }
}