Public with sharing class DirectDebitAuthController {

    Public class authorizedAccount {
        @AuraEnabled
        public string accountName{
            get;
            set;
        }
        @AuraEnabled
        public string company {
            get;
            set;
        }
        @AuraEnabled
        public string sortCode {
            get;
            set;
        }
        @AuraEnabled
        public string accountNumber{
            get;
            set;
        }
        @AuraEnabled
        public string code{
            get;
            set;
        }
        @AuraEnabled
        public dateTime DDEntryDate{
            get;
            set;
        }
        @AuraEnabled
        public boolean DDAuth{
            get;
            set;
        }


    public authorizedAccount(string accountName, string company, String sortCode, string accountNumber, String code, dateTime DDEntryDate, boolean DDAuth) {

            this.accountName = accountName;
			this.company = company;            
			this.sortCode = sortCode;
            this.accountNumber = accountNumber;
            this.code = code;
            this.DDEntryDate = DDEntryDate;
            this.DDAuth = DDAuth;
    }
    }

    @AuraEnabled
	public static List<authorizedAccount> getAuthorizedAccounts() {
        List<authorizedAccount> accounts = new List<authorizedAccount>();
        List < Account > authorizedAccounts = [SELECT Name, dd_account_number__c, Direct_Debit_Details_Entry_Date__c, Direct_Debit_Authorised_Date__c, Direct_Debit_authorised__c, dd_sort_code__c from Account where Enqix_Payment_Method__c = 'Direct Debit' AND Direct_Debit_Details_Entry_Date__c != null AND Direct_Debit_authorised__c = false order by Name];
        Integer numberOfAccounts = Database.countQuery('SELECT COUNT() FROM Account WHERE Enqix_Payment_Method__c = \'Direct Debit\' AND Direct_Debit_Details_Entry_Date__c != null AND Direct_Debit_authorised__c = false');
        system.debug(numberOfAccounts);
        for (Account a : authorizedAccounts) {
            string company = 'FirstMile';
            string code = '0N';

                authorizedAccount aa = new authorizedAccount(a.Name, company, a.dd_sort_code__c, a.dd_account_number__c, code, a.Direct_Debit_Details_Entry_Date__c, a.Direct_Debit_authorised__c);
                accounts.add(aa);
        }
        return accounts;        
   } 

   @AuraEnabled 
   public static String generateCSV(){
       DirectDebitAuthBatch ddbatch = new DirectDebitAuthBatch();
       Database.executeBatch (ddbatch, 50);
       string message = 'Direct debits Authorized will now be processed, an email will be sent when they are finished.';
       return message;
   }
}