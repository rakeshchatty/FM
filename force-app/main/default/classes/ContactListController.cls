public with sharing class ContactListController {

    @AuraEnabled
    public static List<Account> findAll() {
        return [SELECT id, name, phone, BillingStreet FROM Account ORDER BY name ASC LIMIT 15];
    }

    @AuraEnabled
    public static List<Account> findByLocation(String searchKey) {
        String name = '%' + searchKey + '%';
        return [SELECT id, name, phone, BillingStreet FROM Account WHERE BillingStreet LIKE :name ORDER BY name ASC LIMIT 200];
    }

    

}