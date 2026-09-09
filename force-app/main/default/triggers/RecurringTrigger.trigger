trigger RecurringTrigger on Recurrings__c (before insert, before update) {
    //Populate the Last_Working_Day__c and the Next_Date__c
    if(trigger.isinsert){
        //RecurringTriggerHelper rth = new RecurringTriggerHelper();
        RecurringTriggerHelper.populateDates(trigger.new, null); 
    } 
    else {
        RecurringTriggerHelper.populateDates(Trigger.NEW, Trigger.oldMap);
        List <Recurrings__c> recsToValidate = new List <Recurrings__c>();
        //to validate if the product being added to the recurring is an active supplier product on the supplier being added
        For (Recurrings__c rec : trigger.new){
            if (rec.Supplier__c != null && Trigger.oldMap.get(rec.Id).Product__c != rec.Product__c){
                recsToValidate.add(rec);
            }     
        }
        if (recsToValidate.size() > 0){
            RecurringTriggerHelper.validateSupplierProduct(recsToValidate);
        }
    }    
}