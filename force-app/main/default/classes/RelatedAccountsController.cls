/**
* Apex controller for lightning component 'RelatedAccounts'
*
* @Date: 01/02/2018
* @Author: Adeel Ahmad
*
* @TestClass : Test_RelatedAccountsController
*/
public class RelatedAccountsController {
 	@AuraEnabled
    public static List<Account> getChildAccounts(String accId) {
        return [SELECT id, Name, IMAGE__c, BID__c, Linked_Group__c, Partnership__r.Id, Partnership__r.Name FROM Account WHERE ParentId=:accId ORDER BY name ASC];
    }
}