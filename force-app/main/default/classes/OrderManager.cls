/**
* @author Zoran Zunko
* @date 10/22/15
*
* @group Order
* @group-content ../../ApexDocContent/Order
*
* @description
* Holds all constants, business logic and data retrieval methods for Order sObject
*/

public with sharing class OrderManager {

    public static Order createOrderRecordFromCSVLine(List<String> csvLine, Map<String, EnquixImportMappings__c> fieldMappings, Map<String, Integer> headerIndexMap) {

        System.debug(LoggingLevel.DEBUG, 'OrderManager createOrderRecordFromCSVLine - start');
        System.debug(LoggingLevel.FINE, 'csvLine: ' + csvLine);
        System.debug(LoggingLevel.FINE, 'fieldMappings: ' + fieldMappings);

        Order recordSObject =
                (Order)EquixImportManager.copyLineToSObject(
                        new Order()
                        , EnquixImportMappingsManager.ORDER_RECORD_GROUP
                        , csvLine
                        , fieldMappings
                        , headerIndexMap
                );

        // Commented out 2016-01-15 - sometimes these fields may not be mapped but we don't want the upload to fail
        //if(Test.isRunningTest()) {

            if(String.isBlank(recordSObject.Status)) recordSObject.Status = 'Confirmed';
            if(recordSObject.EffectiveDate == null ) recordSObject.EffectiveDate= Date.today();
        //}

        recordSObject.Account = new Account(Enqix_Location_ID__c = csvLine.get(headerIndexMap.get(EnquixImportMappingsManager.ORDER_LOCATION_ID_MAPPING)));
        recordSObject.Pricebook2Id = PricebookEntryManager.getStandardPricebookId();
        System.debug(LoggingLevel.DEBUG, 'recordSObject: ' + recordSObject);
        System.debug(LoggingLevel.DEBUG, 'OrderManager createOrderRecordFromCSVLine - end');
        return recordSObject;
    }
}