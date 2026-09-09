/**
* @author Zoran Zunko
* @date 10/26/15
*
* @group Product
* @group-content ../../ApexDocContent/Product
*
* @description
* Holds all constants, business logic and data retrieval methods for Product sObject
*/

public with sharing class ProductManager {

    public static Product2 createProductRecordFromCSVLine(List<String> csvLine, Map<String, EnquixImportMappings__c> fieldMappings, Map<String, Integer> headerIndexMap) {

        System.debug(LoggingLevel.DEBUG, 'ProductManager createProductRecordFromCSVLine - start');
        System.debug(LoggingLevel.FINE, 'csvLine: ' + csvLine);
        System.debug(LoggingLevel.FINE, 'fieldMappings: ' + fieldMappings);

        Product2 recordSObject =
                (Product2)EquixImportManager.copyLineToSObject(
                        new Product2()
                        , EnquixImportMappingsManager.PRODUCT_RECORD_GROUP
                        , csvLine
                        , fieldMappings
                        , headerIndexMap
                );

        System.debug(LoggingLevel.DEBUG, 'recordSObject: ' + recordSObject);
        System.debug(LoggingLevel.DEBUG, 'ProductManager createProductRecordFromCSVLine - end');
        return recordSObject;
    }

}