/**
* @author Zoran Zunko
* @date 10/26/15
*
* @group OrderLine
* @group-content ../../ApexDocContent/OrderLine
*
* @description
* Holds all constants, business logic and data retrieval methods for OrderLine sObject
*/

public with sharing class OrderLineManager {

    public static OrderItem createOrderItemRecordFromCSVLine(
            List<String> csvLine,
            Map<String, EnquixImportMappings__c> fieldMappings,
            Map<String, Integer> headerIndexMap,
            Map<String, PricebookEntry> pricebookEntriesByProductEnqixIds) {

        System.debug(LoggingLevel.DEBUG, 'OrderLineManager createOrderRecordFromCSVLine - start');
        System.debug(LoggingLevel.FINE, 'csvLine: ' + csvLine);
        System.debug(LoggingLevel.FINE, 'fieldMappings: ' + fieldMappings);

        OrderItem recordSObject =
                (OrderItem)EquixImportManager.copyLineToSObject(
                        new OrderItem()
                        , EnquixImportMappingsManager.ORDER_LINE_RECORD_GROUP
                        , csvLine
                        , fieldMappings
                        , headerIndexMap
                );

        recordSObject.Order = new Order(Enqix_ID__c = csvLine.get(headerIndexMap.get(EnquixImportMappingsManager.ORDER_ID_MAPPING)));
        recordSObject.PricebookEntryId = pricebookEntriesByProductEnqixIds.get(csvLine.get(headerIndexMap.get(EnquixImportMappingsManager.ORDER_LINE_PRODUCT_ID_MAPPING))).Id;
        System.debug(LoggingLevel.DEBUG, 'recordSObject: ' + recordSObject);
        System.debug(LoggingLevel.DEBUG, 'OrderLineManager createOrderRecordFromCSVLine - end');
        return recordSObject;
    }

}