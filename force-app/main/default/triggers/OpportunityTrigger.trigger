trigger OpportunityTrigger on Opportunity (after update) {
    
    list<Account> AccountsToUpdate = new list<Account>();
    for(Opportunity opp : [Select Id, AccountId, Account.Opportunity__c, StageName from Opportunity where Id IN :trigger.newMap.keyset()]){
        if(opp.AccountId != null && opp.Account.Opportunity__c == null && opp.StageName == 'Handed Over' && trigger.oldmap.get(opp.Id).StageName != opp.StageName){
            Account acc = new Account();
            acc.Id = opp.AccountId;
            acc.Opportunity__c = opp.Id;
            acc.Primary_Opportunity_Issue__c = system.now();
            AccountsToUpdate.add(acc);
        }
    }
    system.debug(AccountsToUpdate.size());
    if(AccountsToUpdate.size() > 0)
    update AccountsToUpdate ;
}