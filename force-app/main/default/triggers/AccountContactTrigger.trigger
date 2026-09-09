trigger AccountContactTrigger on Contact (after update, after insert) {
    
    List<Account> accountsToUpdate = new List<Account>();
    List<Id> accountIds = new List<Id>();    
    
    //Get the Account Ids needed to update
    for(Contact c : trigger.new){
        accountIds.add(c.AccountId);        
    }
    
    List<Account> accounts = [SELECT LastModifiedDate,Transferred_To_Enqix__c FROM Account WHERE Id IN :accountIds AND RecordType.DeveloperName != 'Prospect'];
    //Update each account
    for(Account a: accounts){
       a.Transferred_To_Enqix__c = false;
       accountsToUpdate.add(a);
    }
    update accountsToUpdate;
}