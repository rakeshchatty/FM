global class Pricebook_AccountUpdateBatch implements Database.Batchable<sObject>{

    global Map<Decimal, PricebookChangeInfo> changedPricebooks = new Map<Decimal, PricebookChangeInfo>();

    global Database.QueryLocator start(Database.BatchableContext BC){

        system.System.debug('Searching for accounts to update.');
        String priceBookCodesStr = ''+changedPricebooks.keySet();
        priceBookCodesStr = priceBookCodesStr.replace('{', '(');
        priceBookCodesStr = priceBookCodesStr.replace('}', ')');
        String query = 'SELECT Id,Price_Book__c, Price_Book__r.Enqix_Code__c FROM Account WHERE Price_Book__c != null AND Price_Book__r.Enqix_Code__c IN '+priceBookCodesStr;
        system.debug('Searched query: '+query);
        Database.QueryLocator queryResult = Database.getQueryLocator(query);
        return  queryResult;
    }
 
   global void execute(Database.BatchableContext BC, List<Account> scope){
        //system.debug('Searching for accounts to update. Scope size: '+scope.size());
        for(Account account : scope){
            //system.System.debug('Account\'s price book: '+account.Price_Book__c + ' / Price book code: '+account.Price_Book__r.Enqix_Code__c);
            //system.System.debug('Updated price book: '+changedPricebooks);
            if (changedPricebooks.containsKey(account.Price_Book__r.Enqix_Code__c) || changedPricebooks.containsKey((Integer)account.Price_Book__r.Enqix_Code__c))
            {
                //system.debug('changing account\'s price book: '+account); 
                account.Price_Book__c = changedPricebooks.get((Integer)account.Price_Book__r.Enqix_Code__c).newPricebookVersion;
            }
        }
        Database.SaveResult[] resultsCN = Database.update(scope, false);
        List<sObject> records = scope;
        String process = 'Update price book on historic accounts';
        String action = 'Update';
        String sObjectType = 'Account';
        String ParentField = '';
        
        LogRegister.createLogsUpsert(resultsCN, records, process, action, sObjectType, ParentField);
        //update scope; 
        //system.System.debug('Accounts updated on batch.');
    }

    global void finish(Database.BatchableContext BC){
        system.System.debug('Ending Accounts batch.');
    }
}