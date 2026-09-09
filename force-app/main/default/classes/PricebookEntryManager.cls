/**
* @author Zoran Zunko
* @date 10/26/15
*
* @group PricebookEntry
* @group-content ../../ApexDocContent/PricebookEntry
*
* @description
* Holds all constants, business logic and data retrieval methods for PricebookEntry sObject
*/

public with sharing class PricebookEntryManager {

    public static Map<String, PricebookEntry> getPricebookEntriesByProductEnqixIds(List<String> prodcutEnqixIds) {

        System.debug(LoggingLevel.DEBUG, 'PricebookEntryManager getPricebookEntriesByProductEnqixIds - start');
        Map<String, PricebookEntry> response = new Map<String, PricebookEntry>();
        for (PricebookEntry pbEntry :
        [
                SELECT Id, Product2.Enqix_Id__c
                FROM PricebookEntry
                WHERE Product2.Enqix_Id__c IN :prodcutEnqixIds
        ]) {

            response.put(pbEntry.Product2.Enqix_Id__c, pbEntry);
        }

        System.debug(LoggingLevel.FINE, 'response: ' + response);
        System.debug(LoggingLevel.DEBUG, 'PricebookEntryManager getPricebookEntriesByProductEnqixIds - end');
        return response;
    }

    @testVisible static Id standardPricebookId;
    public static Id getStandardPricebookId() {

        if(Test.isRunningTest()) return Test.getStandardPricebookId();
        
        if (standardPricebookId == null) {

            standardPricebookId = [
                    SELECT id
                    FROM Pricebook2
                    WHERE IsStandard = TRUE
                            AND IsActive = TRUE
                    LIMIT 1
            ].Id;

        }

        return standardPricebookId;
    }

    public static PricebookEntry createStandardEntryFromProduct(Product2 product) {

        return new PricebookEntry(
                IsActive = true,
                Pricebook2Id = getStandardPricebookId(),
                Product2Id = product.Id,
                UnitPrice = 0.0,
                UseStandardPrice = false
        );
    }

}