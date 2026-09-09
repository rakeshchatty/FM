global class wasteTransferNoteDueBatch implements Database.Batchable < sObject > {
    
    String query;
    
    global wasteTransferNoteDueBatch(){
        String Dead = 'Dead';
        query = 'SELECT Id, EndDate__c, MostRecent__c, Account__c , Account__r.Waste_transfer_note_due__c, Account__r.Enqix_Dead_Live__c From Compliance_Doc__c Where MostRecent__c = True And EndDate__c = TODAY And Account__r.Enqix_Dead_Live__c != \''+Dead+'\'';
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC) {
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List < SObject > scope) {
        
        Map <Account, List<Compliance_Doc__c>> accountToComplianceDocs = new Map <Account, List<Compliance_Doc__c>>();
        List <Account> accToUpdate = new List <Account>();
        for(SObject cd : scope){
            
            Compliance_Doc__c a = (Compliance_Doc__c) cd;
            
            if(accountToComplianceDocs.containskey(a.Account__r))
            {
                accountToComplianceDocs.get(a.Account__r).add(a);
            }else
            {
                List<Compliance_Doc__c> listOfcds = new List<Compliance_Doc__c>();
                listOfcds.add(a);
                accountToComplianceDocs.put(a.Account__r, listOfcds);
            }
            
            for (Account op: accountToComplianceDocs.keySet()) {
                op.Waste_transfer_note_due__c = True;
                accToUpdate.add(op);
            }
        }
        
        //Remove duplicate items from accToUpdate List
        Set<sobject> myset = new Set<sobject>();
        List<sobject> result = new List<sobject>();
        for (sobject s : accToUpdate) {
            if (myset.add(s)) {
                result.add(s);
            }
        }
        update result;
    }
    
    global void finish(Database.BatchableContext BC) {
        
    }
}