public class CaseTriggerHandler{
    
    /*public void UpdateContaminationField(list<Case> Cases) { 
        set<Id> account_Id = new set<Id>();
        for(Case c: Cases){
            account_Id.add(c.AccountId);
        }
        List<Account> list_Account = new List<Account>();
        system.debug('list_Account' + list_Account);   
        Decimal Sum;
        for(Account objAccount : [SELECT Id, Name, contaminationCount__c FROM Account WHERE Id IN: account_Id]){
            Sum=0;
            for(Case objCase : [Select Id, Ops_Issue_Type__c, AccountId from Case WHERE AccountId =: objAccount.Id AND Ops_Issue_Type__c = 'Contamination']){
                system.debug('objCase -- ' + objCase);                
                system.debug('objCase.ContentDocumentLinks--'+ objCase.ContentDocumentLinks);                     
                    List<ContentDocumentLink> CD = [Select Id, LinkedEntityId From ContentDocumentLink Where LinkedEntityId =: objCase.Id];                                            
                        if(CD.size() > 0 ){
                            Sum = Sum + 1;                   
                        }
                    system.debug('SUM' + Sum);  
            }
            objAccount.contaminationCount__c=Sum;
            list_Account.add(objAccount);
        } 
        update list_Account;
    }*/

    public void UpdateContaminationField(list<Case> Cases) {
        system.debug('Entering case helper');

        set<Id> account_Id = new set<Id>();
        for(Case c: Cases){
            account_Id.add(c.AccountId);
        }

        Map<Id, Account> accountsMap = new Map<Id, Account>([SELECT Id, Name, contaminationCount__c FROM Account WHERE Id IN: account_Id]);
        for (Account a : accountsMap.values()) {
            a.contaminationCount__c = 0;
        }
        for(Case objCase : [SELECT AccountId, (SELECT Id FROM ContentDocumentLinks) from Case WHERE AccountId IN :account_Id AND Ops_Issue_Type__c = 'Contamination']){
            if (objCase.ContentDocumentLinks.size() > 0) {
                if(accountsMap.get(objCase.AccountId) != null){
                    Account a = accountsMap.get(objCase.AccountId);
                    a.contaminationCount__c += 1;
                    accountsMap.put(a.Id, a);
                }
            }
            system.debug('objCase -- ' + objCase);                
            system.debug('objCase.ContentDocumentLinks--'+ objCase.ContentDocumentLinks);
        }
        try {
            system.debug(accountsMap.values());
            update accountsMap.values();
        }
        catch (Exception e) {
            system.debug(e.getMessage());
        }
    }
    
    
    
    public void UpdateCaseRecordType(list<Case> Cases){
        
        List<RecordType> CaseRecordTypes = new list<RecordType>();
        CaseRecordTypes = [Select Id, Name from recordType where sObjectType = 'Case' and isActive = true];
        Map<string, Id> RecordTypeMap = new Map<string, Id>();
        for(RecordType rt : CaseRecordTypes){
            RecordTypeMap.put(rt.Name, rt.Id);
        }
        
        List<Case_Types__c> CaseSetting = Case_Types__c.getall().values();
        map<string, string> SettingMap = new map<string, string>();
        for(Case_Types__c ct : CaseSetting){
            SettingMap.put(ct.Case_Type__c, ct.Case_Record_Type_Name__c);
        }
        
        for(Case c : Cases){
            if(c.Type != null){
                string RecordTypeName = SettingMap.get(c.Type);
                
                if(RecordTypeName != null){
                    Id RecordTypeId = RecordTypeMap.get(RecordTypeName);
                    if(RecordTypeId != null){
                        c.RecordTypeId = RecordTypeId;
                    }
                }
            }
        }
    }
}