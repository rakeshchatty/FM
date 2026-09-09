public with sharing class CompetitorController {

    @AuraEnabled
    public static List<Competitor__c> findAll() {
        return [SELECT id, name FROM Competitor__c ORDER BY name ASC LIMIT 50];
    }

    @AuraEnabled
    public static List<Competitor__c> findByCompetitor(String searchKey) {
        String name = '%' + searchKey + '%';
        return [SELECT id, name FROM Competitor__c WHERE name LIKE :name ORDER BY name ASC LIMIT 50];
    }

    

}