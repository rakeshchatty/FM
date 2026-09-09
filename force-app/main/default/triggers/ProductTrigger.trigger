trigger ProductTrigger on Product2(before update, after update) {
    
    if(Trigger.isUpdate){
        if(Trigger.isAfter){
            //jira 1945 - Force update on the related pricebook entries
            List <PricebookEntry> entriesToUpdate = new List <PricebookEntry>();
            for (Product2 prod : trigger.new){
                if(Trigger.newMap.get(prod.Id).name != Trigger.oldMap.get(prod.Id).name){
                    entriesToUpdate = [Select Id from PricebookEntry where Product2Id =: prod.Id];
                }  
                system.debug('Update entries');
                if (entriesToUpdate.size() > 0){
                    system.debug('Update entries');
                    update entriesToUpdate;
                }
            }
        }
    }
}