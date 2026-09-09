/**
* @author Zoran Zunko
* @date 9/30/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

public with sharing class EquixImportManager {

    @TestVisible private static Integer logFieldLength;

    public static Integer getLogFieldLength() {

        if (logFieldLength == null) {

            logFieldLength = Enqix_Import__c.Log__c.getDescribe().getLength();
        }

        return logFieldLength;
    }

    private static Map<String, Integer> monthsMap = new Map<String, Integer> {
            'Jan' => 1,
            'Feb' => 2,
            'Mar' => 3,
            'Apr' => 4,
            'May' => 5,
            'Jun' => 6,
            'Jul' => 7,
            'Aug' => 8,
            'Sep' => 9,
            'Oct' => 10,
            'Nov' => 11,
            'Dec' => 12

    };

    private static Integer convertMonthTextToNumber(String month) {
        return monthsMap.get(month);
    }

    public static final String IMPORT_TYPE_ACCOUNT = 'Accounts/Locations';
    public static final String IMPORT_TYPE_ORDER = 'Orders';

    public static final String STATUS_NEW = 'New';
    public static final String STATUS_PENDING = 'Pending';
    public static final String STATUS_IN_PROGRESS = 'In Progress';
    public static final String STATUS_COMPLETED = 'Completed';
    public static final String STATUS_ERROR = 'Error';

    @TestVisible private static Map<String, Map<String, Map<String, EnquixImportMappings__c>>> importMappingMap;

    public static Map<String, Map<String, Map<String, EnquixImportMappings__c>>> getImportMappingMap() {

        System.debug(LoggingLevel.DEBUG, 'EquixImportManager getImportMappingMap start ');
        System.debug(LoggingLevel.DEBUG, 'importMappingMap: ' + importMappingMap);

        if (importMappingMap == null || importMappingMap.size() == 0) {

            importMappingMap = new Map<String, Map<String, Map<String, EnquixImportMappings__c>>>();
            for (EnquixImportMappings__c mapping: EnquixImportMappingsManager.getEnquixImportMappings().values()) {

                if (importMappingMap.get(mapping.ImportType__c) == null) {

                    importMappingMap.put(mapping.ImportType__c, new Map<String, Map<String, EnquixImportMappings__c>>());
                }
                if (importMappingMap.get(mapping.ImportType__c).get(mapping.SalesforceRecordGroup__c) == null) {

                    importMappingMap.get(mapping.ImportType__c).put(mapping.SalesforceRecordGroup__c, new Map<String, EnquixImportMappings__c>());
                }

                importMappingMap.get(mapping.ImportType__c).get(mapping.SalesforceRecordGroup__c).put(mapping.EnquixHeaderValue__c, mapping);
            }
            System.debug(LoggingLevel.DEBUG, 'importMappingMap: ' + importMappingMap);
        }
        System.debug(LoggingLevel.DEBUG, 'EquixImportManager getImportMappingMap end');
        return importMappingMap;
    }

    public static List<Enqix_Import__c> getPendingEnqixImports(String importType) {

        System.debug(LoggingLevel.DEBUG, 'EquixImportManager getPendingEnqixImports start');
        List<Enqix_Import__c> enqixImports = [
                SELECT Log__c, Status__c, Type__c
                FROM Enqix_Import__c
                WHERE Status__c = :STATUS_PENDING
                AND Type__c = :importType
                ORDER BY CreatedDate ASC
        ];
        System.debug(LoggingLevel.DEBUG, 'enqixImports.size(): ' + enqixImports.size());
        System.debug(LoggingLevel.DEBUG, 'EquixImportManager getPendingEnqixImports end');

        return enqixImports;
    }

    public static Attachment getLatestAttachmentForEnqixImport(Id enquixImportId) {

        System.debug(LoggingLevel.DEBUG, 'EquixImportManager getLatestAttachmentForEnqixImport start');

        List<Attachment> attachments = [
                SELECT Body
                FROM Attachment
                WHERE ParentId = :enquixImportId
                ORDER BY LastModifiedDate DESC
                LIMIT 1
        ];

        if (attachments.size() == 0) {

            throw new EnquixImportException('No attachments exist for Enqix Import: ' + enquixImportId);
        }
        System.debug(LoggingLevel.DEBUG, 'attachments.size(): ' + attachments.size());
        System.debug(LoggingLevel.DEBUG, 'EquixImportManager getLatestAttachmentForEnqixImport end');

        return attachments[0];
    }

    public static Map<String, Integer> processHeader(List<String> headers) {

        System.debug(LoggingLevel.DEBUG, 'EquixImportManager processHeader start');
        System.debug(LoggingLevel.DEBUG, 'headers: ' + headers);
        Map<String, Integer> headerMap = new Map<String, Integer>();

        for (Integer i = 0; i < headers.size(); i++) {

            headerMap.put(headers[i], i);
        }

        System.debug(LoggingLevel.DEBUG, 'headerMap: ' + headerMap);
        System.debug(LoggingLevel.DEBUG, 'EquixImportManager processHeader end');
        return headerMap;
    }

    public static SObject copyLineToSObject(
            SObject recordSObject
            , String recordGroup
            , List<String> csvLine
            , Map<String, EnquixImportMappings__c> fieldMappings
            , Map<String, Integer> headerIndexMap) {

        System.debug(LoggingLevel.DEBUG, 'EquixImportManager copyLineToSObject - start');
        System.debug(LoggingLevel.FINE, 'recordSObject: ' + recordSObject);
        System.debug(LoggingLevel.FINE, 'csvLine: ' + csvLine);

        for (String header : headerIndexMap.keySet()) {
            System.debug(LoggingLevel.FINE, 'header: ' + header);
            System.debug(LoggingLevel.FINE, 'fieldMappings.get(header): ' + fieldMappings.get(header));
            try {
                String elementValue = csvLine.get(headerIndexMap.get(header));
                if (
                    (
                     header == EnquixImportMappingsManager.START_DATE_MAPPING || 
                     header == EnquixImportMappingsManager.END_DATE_MAPPING || 
                     header == EnquixImportMappingsManager.ORDER_EFFECTIVE_DATE_MAPPING || 
                     header == EnquixImportMappingsManager.ORDER_DELIVERY_DATE_MAPPING || 
                     header == EnquixImportMappingsManager.ORDER_INV_SERV_NOTE_DATE
                     ) && String.isNotBlank(elementValue)
                    ) {
                    Integer dateYear;
                    Integer dateMonth;
                    Integer dateDay;

                    String datePart = elementValue.split(' ')[0];
                    List<String> dateParts = datePart.split('/');

                    dateYear = Integer.valueOf(dateParts[2]);
                    dateMonth = Integer.valueOf(dateParts[1]);
                    dateDay = Integer.valueOf(dateParts[0]);

                    if (dateYear != null && dateMonth != null && dateDay != null) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Date.newInstance(dateYear, dateMonth, dateDay));
                    }
                    /*Integer dateYear = Integer.valueOf(elementValue);
                    Integer dateMonth = convertMonthTextToNumber(
                            csvLine.get(
                                    headerIndexMap.get(
                                            EnquixImportMappingsManager.START_DATE_MONTH_MAPPING)
                            )
                    );

                    if (dateYear != null && dateMonth != null) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Date.newInstance(dateYear, dateMonth, 0));
                    }*/
                }
                /*else if (header == EnquixImportMappingsManager.END_DATE_MAPPING) {
                    Integer dateYear;
                    Integer dateMonth;
                    Integer dateDay;

                    String datePart = elementValue.split(' ')[0];
                    List<String> dateParts = datePart.split('/');

                    dateYear = Integer.valueOf(dateParts[2]);
                    dateMonth = Integer.valueOf(dateParts[1]);
                    dateDay = Integer.valueOf(dateParts[0]);

                    if (dateYear != null && dateMonth != null && dateDay != null) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Date.newInstance(dateYear, dateMonth, dateDay));
                    }
//                    Integer dateYear = Integer.valueOf(elementValue);
//                    Integer dateMonth = convertMonthTextToNumber(
//                            csvLine.get(
//                                    headerIndexMap.get(
//                                            EnquixImportMappingsManager.END_DATE_MONTH_MAPPING)
//                            )
//                    );
//                    if (dateYear != null && dateMonth != null) {
//                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Date.newInstance(dateYear, dateMonth, 0));
//                    }
                }*/
                else if (header == EnquixImportMappingsManager.COLLECTION_STREET_MAPPING1) {

                    String colStreet1 = csvLine.get(
                            headerIndexMap.get(
                                    EnquixImportMappingsManager.COLLECTION_STREET_MAPPING1)
                    );
                    String colStreet2 = csvLine.get(
                            headerIndexMap.get(
                                    EnquixImportMappingsManager.COLLECTION_STREET_MAPPING2)
                    );
                    String colStreet3 = csvLine.get(
                            headerIndexMap.get(
                                    EnquixImportMappingsManager.COLLECTION_STREET_MAPPING3)
                    );
                    String colStreet = '';
                    if (!String.isBlank(colStreet1)) {
                        colStreet += colStreet1;
                    }
                    if (!String.isBlank(colStreet2)) {
                        colStreet += ( String.isBlank(colStreet) ? '' : ', ' ) + colStreet2;
                    }
                    if (!String.isBlank(colStreet3)) {
                        colStreet += ( String.isBlank(colStreet) ? '' : ', ' ) + colStreet3;
                    }
                    recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, colStreet);
                }
                else if (header == EnquixImportMappingsManager.DELIVERY_STREET_MAPPING1) {

                    String delStreet1 = csvLine.get(
                            headerIndexMap.get(
                                    EnquixImportMappingsManager.DELIVERY_STREET_MAPPING1)
                    );
                    String delStreet2 = csvLine.get(
                            headerIndexMap.get(
                                    EnquixImportMappingsManager.DELIVERY_STREET_MAPPING2)
                    );
                    String delStreet3 = csvLine.get(
                            headerIndexMap.get(
                                    EnquixImportMappingsManager.DELIVERY_STREET_MAPPING3)
                    );
                    String delStreet = '';
                    if (!String.isBlank(delStreet1)) {
                        delStreet += delStreet1;
                    }
                    if (!String.isBlank(delStreet2)) {
                        delStreet += ( String.isBlank(delStreet) ? '' : ', ' ) + delStreet2;
                    }
                    if (!String.isBlank(delStreet3)) {
                        delStreet += ( String.isBlank(delStreet) ? '' : ', ' ) + delStreet3;
                    }
                    recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, delStreet);
                }
                else if (fieldMappings.get(header) != null && fieldMappings.get(header).SalesforceFieldAPIName__c != 'null' && fieldMappings.get(header).CopyValueFromSheet__c) {

                    System.debug(LoggingLevel.DEBUG, 'fieldMappings.get(header).SalesforceFieldAPIName__c: ' + fieldMappings.get(header).SalesforceFieldAPIName__c);
                    System.debug(LoggingLevel.DEBUG, 'recordSObject.getSObjectType().getDescribe().fields.getMap().get(fieldMappings.get(header).SalesforceFieldAPIName__c): ' + recordSObject.getSObjectType().getDescribe().fields.getMap().get(fieldMappings.get(header).SalesforceFieldAPIName__c));
                    Schema.DisplayType fieldType = recordSObject.getSObjectType().getDescribe().fields.getMap().get(fieldMappings.get(header).SalesforceFieldAPIName__c).getDescribe().getType();
                    if (fieldType == Schema.DisplayType.Double) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Double.valueOf(elementValue));
                    }
                    else if (fieldType == Schema.DisplayType.Integer) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Integer.valueOf(elementValue));
                    }
                    else if (fieldType == Schema.DisplayType.CURRENCY) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Double.valueOf(elementValue));
                    }
                    else if (fieldType == Schema.DisplayType.Percent) {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, Decimal.valueOf(elementValue));
                    }
                    else if (fieldType == Schema.DisplayType.Date) {
                        List<String> dateParts = elementValue.split(' ')[0].replace(' ', '').split('/');

                        Date formDate = Date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[0]), Integer.valueOf(dateParts[1]));
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, formDate);
                    }
                    else {
                        recordSObject.put(fieldMappings.get(header).SalesforceFieldAPIName__c, elementValue);
                    }
                }
                System.debug('elementValue: ' + elementValue);
            }
            catch (Exception ex) {

                System.debug(LoggingLevel.ERROR, 'header: ' + header);
                System.debug(LoggingLevel.ERROR, 'fieldMappings.get(header): ' + fieldMappings.get(header));
                System.debug(LoggingLevel.DEBUG, 'csvLine.get(headerIndexMap.get(header)): ' + csvLine.get(headerIndexMap.get(header)));
                System.debug(LoggingLevel.WARN, ex.getMessage() + ' ' + ex.getStackTraceString());
            }
        }

        System.debug(LoggingLevel.DEBUG, 'EquixImportManager copyLineToSObject - end');
        return recordSObject;
    }
}