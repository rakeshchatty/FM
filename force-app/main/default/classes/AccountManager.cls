/**
* @author Zoran Zunko
* @date 10/22/15
*
* @group Account
* @group-content ../../ApexDocContent/Account
*
* @description
* Holds all constants, business logic and data retrieval methods for Account sObject
*/

public with sharing class AccountManager {

    public static String RT_ACCOUNT = 'Account.Account';
    public static String RT_LOCATION = 'Account.Location';
    public static String RT_SUBCONTRACTOR = 'Account.Subcontractor';

    /*@TestVisible private static List<String> startDateFields;
    public static List<String> getStartDateFields() {

        if (startDateFields == null) {

            startDateFields = new List<String> {
                    EnquixImportMappingsManager.START_DATE_YEAR_MAPPING, EnquixImportMappingsManager.START_DATE_MONTH_MAPPING
            };
        }

        return startDateFields;
    }*/

    public static Account createAccountRecordFromCSVLine(List<String> csvLine, Map<String, EnquixImportMappings__c> fieldMappings, Map<String, Integer> headerIndexMap) {

        System.debug(LoggingLevel.DEBUG, 'AccountManager createAccountRecordFromCSVLine - start');
        System.debug(LoggingLevel.FINE, 'csvLine: ' + csvLine);
        System.debug(LoggingLevel.FINE, 'fieldMappings: ' + fieldMappings);

        Account recordSObject =
                (Account) EquixImportManager.copyLineToSObject(
                        new Account(RecordTypeId = Cache.RecordTypeId(RT_ACCOUNT))
                        , EnquixImportMappingsManager.ACCOUNT_RECORD_GROUP
                        , csvLine
                        , fieldMappings
                        , headerIndexMap
                );

        System.debug(LoggingLevel.DEBUG, 'recordSObject: ' + recordSObject);
        System.debug(LoggingLevel.DEBUG, 'AccountManager createAccountRecordFromCSVLine - end');
        return recordSObject;
    }

    public static Account createLocationRecordFromCSVLine(List<String> csvLine, Map<String, EnquixImportMappings__c> fieldMappings, Map<String, Integer> headerIndexMap) {

        System.debug(LoggingLevel.DEBUG, 'AccountManager createAccountRecordFromCSVLine - start');
        System.debug(LoggingLevel.FINE, 'csvLine: ' + csvLine);
        System.debug(LoggingLevel.FINE, 'fieldMappings: ' + fieldMappings);

        Account recordSObject =
                (Account) EquixImportManager.copyLineToSObject(
                        new Account(RecordTypeId = Cache.RecordTypeId(RT_LOCATION))
                        , EnquixImportMappingsManager.ACCOUNT_RECORD_GROUP
                        , csvLine
                        , fieldMappings
                        , headerIndexMap
                );
        recordSObject.Parent = new Account(Enqix_ID__c = csvLine.get(headerIndexMap.get(EnquixImportMappingsManager.PARENT_ID_LOCATION_MAPPING)));
        System.debug(LoggingLevel.DEBUG, 'recordSObject: ' + recordSObject);
        System.debug(LoggingLevel.DEBUG, 'AccountManager createAccountRecordFromCSVLine - end');
        return recordSObject;
    }

}