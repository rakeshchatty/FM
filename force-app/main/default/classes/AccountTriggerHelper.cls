public class AccountTriggerHelper {
    public static void cancelSubscribedProducts(Account oldAcc) {
        List<Subscribed_Products__c> subsProdsToDelete = new List <Subscribed_Products__c>();
        for(Account acc : [Select id, (Select id, Partnership__c from Subscribed_Products__r where Partnership__c =: oldAcc.Partnership__r.Name) from Account where id =: oldAcc.Id]){
            subsProdsToDelete.addAll(acc.Subscribed_Products__r);
        }
        system.debug('subsProdsToDelete -->'+subsProdsToDelete);
        delete subsProdsToDelete;
    }
    
    /*
* 2019-05-08 / JIRA 1487 -> Automatic creation of Subscribed products for partner locations and supplier locations
*/
    public static void createSubscribedProducts(List<Account> accs, List<Account_Discount__c> accDisc) {
        List<Subscribed_Products__c> subsProdsToCreate = new List <Subscribed_Products__c>();
        for(Account acc : accs){
            for(Account_Discount__c accDis : accDisc){
                if(accDis.DiscountSupStartDate__c != null){
                    Integer month = accDis.DiscountSupStartDate__c.day();
                    Integer year = accDis.DiscountSupStartDate__c.month();
                }
                Subscribed_Products__c subProd = new Subscribed_Products__c();
                subProd.Account__c = acc.Id;
                subProd.Product__c = accDis.Product__c;
                subProd.Enqix_BID_Location_Limit_Period__c = 'Annual';
                if(accDis.DiscountSupStartDate__c > system.today()){
                    subProd.StartDate__c = Date.newInstance(System.today().Year()-1, accDis.DiscountSupStartDate__c.month(), accDis.DiscountSupStartDate__c.day());
                }else{
                    subProd.StartDate__c = Date.newInstance(System.today().Year(), accDis.DiscountSupStartDate__c.month(), accDis.DiscountSupStartDate__c.day());   
                }
                subProd.Quantity_Remaining__c = 0;
                
                subsProdsToCreate.add(subProd);
            }
        }
        system.debug('subsProdsToCreate -- > '+subsProdsToCreate);
        if(subsProdsToCreate.size() > 0){
            insert subsProdsToCreate;
        }
    }
    
    //Jira 1659 --> " Waste_transfer_note_due__c should also be ticked automatically when a location with no collection schedules places an order "
    public static void updateAcc(Set<Id> accIds) {
        
        system.debug('entered helper account');
        
        List <Account> acc = [Select Id, Waste_transfer_note_due__c, (Select Id From Collections__r) From Account Where Id IN :accIds];
        List <Compliance_Doc__c> wtns = [Select Id from Compliance_Doc__c Where Account__c IN :accIds AND EndDate__c >= TODAY LIMIT 1];
        
        system.debug('acc.size -->' + acc.size());
        system.debug('wtns.size -->' + wtns.size());
        
        List <Account> accToUpdate = new List <Account>(); 
        for (Account acco: acc) { 
            //JIRA 1657 - only check if orederd products and account do not have collection schedules
            if(acco.collections__r.size() == 0 && wtns.size() == 0){
                acco.Waste_transfer_note_due__c = True;
                accToUpdate.add(acco);
            }
        }
        if(accToUpdate.size() > 0){
            update accToUpdate;
        }
    }
}