trigger SubscribedProductsTrigger on Subscribed_Products__c(after insert, before update, before insert) {
//Before insert or update: Update Next Refresh Date on the helper class. Doesn't need to update list. It updates itself.
//After Insert: update the quantityOrdered. Needs to updateList. (comments made by Jessica)
//The code was migrated to the Helper.

    List < Subscribed_Products__c > updateList = new List < Subscribed_Products__c > ();

    if (Trigger.IsInsert && Trigger.isAfter) {
            //This code was here before
            Set < Id > subscribedProductsIds = new Set < Id > ();

            for (Subscribed_Products__c p: trigger.new) {
                subscribedProductsIds.add(p.Id);
            }
            List < Subscribed_Products__c > subscribedProductsData = [SELECT  Account__r.Enqix_Location_ID__c, Account__r.RecordType.DeveloperName,Product__r.Id, Product__r.Enqix_Id__c, Product__r.Name
                FROM Subscribed_Products__c WHERE Id IN: subscribedProductsIds
            ];     
            for (Subscribed_Products__c p: subscribedProductsData) {                     
                if (p.Account__r.RecordType.DeveloperName != 'Prospect') {
                    //2019-04-08 [JIRA-1536] -> Changed Product.Enqix_ID__c for Product.Id
                    p.Enqix_ID__c = p.Account__r.Id + '|' + p.Product__r.Id;
                    updateList.add(p);
                }
            }

            //957 populateQuantityOrdered
            List<Subscribed_Products__c> lista_produtos_s = new List<Subscribed_Products__c>();
            for(Subscribed_Products__c p : trigger.new){
                lista_produtos_s.add(p);
            }
            SubscribedProductsTriggerHelper helper = new SubscribedProductsTriggerHelper();
            helper.populateQuantityOrdered(lista_produtos_s);
            //END 957
    }

    //TODO update NextRefreshDate__c to StartDate + something, depending of the Enqix_BID_Location_Limit_Period__c
    if(Trigger.isbefore){
        List<Subscribed_Products__c> lista = new List<Subscribed_Products__c>();
        for(Subscribed_Products__c p : trigger.new){
            lista.add(p);
        }
        SubscribedProductsTriggerHelper helper = new SubscribedProductsTriggerHelper();
        helper.updateData(lista);
    }

    //Being used for the code that was here
    if (updateList.size() > 0) {
        system.debug('updatelist::::' + updateList);
        Map<Id,Subscribed_Products__c> removeD = new Map<Id, Subscribed_Products__c>();
        for(Subscribed_Products__c ppp : updateList){
            removeD.put(ppp.Id, ppp);
        }
        List<Subscribed_Products__c> updateListWithoutDups = new List<Subscribed_Products__c>(removeD.values());
        update updateListWithoutDups;
    }

}