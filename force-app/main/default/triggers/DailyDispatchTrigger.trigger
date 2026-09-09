trigger DailyDispatchTrigger on DailyDispatch__c (before insert, after update) {
    List<DailyDispatch__c> scope = new List<DailyDispatch__c>();

    if (Trigger.IsInsert) {
        if (Trigger.IsBefore) DailyDispatchTriggerHelper.beforeInsert(Trigger.New);
    }
    
    //Jira 1968 --> This process that creates the orders after the EndTime is updated, will now be done via batch class (DailyDispatchOrderCreationBatch)
    /*if(Trigger.isUpdate){
        for(DailyDispatch__c d : trigger.new){
            // JIRA 1037 -> Bruno 22-10-2018
            if (Trigger.oldMap.get(d.Id).EndTime__c == null && d.EndTime__c != null && d.Already_Created__c == false) {
                scope.add(d);   
            }
        }
		system.debug(scope.size());
        if(scope.size()>0){
            DailyDispatchTriggerHelper.afterUpdate(scope);
        }
        
    }*/
}