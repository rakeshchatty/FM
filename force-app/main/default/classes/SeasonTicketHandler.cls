public with sharing class SeasonTicketHandler {

    @InvocableMethod(label='Create Compliance Document' description='Given a list of sObjects (Compliance Document), removes the duplicate records' category='Compliance Document')
    public static List<Id> createComplianceDoc(List<Compliance_Doc__c> complianceDocList) {
        List<Id> complianceDocumentId = new List<Id>();
        Set<Compliance_Doc__c> uniqueDocs = new Set<Compliance_Doc__c>(complianceDocList);
        List<Compliance_Doc__c> docsToInsert = new List<Compliance_Doc__c>(uniqueDocs);
        // insert new List<Compliance_Doc__c>(uniqueDocs);
        for(Compliance_Doc__c comDoc : docsToInsert) {
            complianceDocumentId.add(comDoc.Id);
        }
        return complianceDocumentId;
    }
}