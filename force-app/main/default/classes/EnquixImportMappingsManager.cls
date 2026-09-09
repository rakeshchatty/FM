/**
* @author Zoran Zunko
* @date 9/30/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

public with sharing class EnquixImportMappingsManager {

//    public static String START_DATE_YEAR_MAPPING = 'StartYear';
//    public static String START_DATE_MONTH_MAPPING = 'StartMonth';
    //public static String START_DATE_MAPPING = 'Start Date'; // Removed 2016-01-11 David
    public static String START_DATE_MAPPING = 'DateMadeLive';
//    public static String END_DATE_YEAR_MAPPING = 'EndYear';
//    public static String END_DATE_MONTH_MAPPING = 'EndMonth';
    //public static String END_DATE_MAPPING = 'Dead Date'; // Removed 2016-01-11 David
    public static String END_DATE_MAPPING = 'DateMarkedDead';
    public static String DELIVERY_STREET_MAPPING1 = 'AddressLine1';
    public static String DELIVERY_STREET_MAPPING2 = 'AddressLine2';
    public static String DELIVERY_STREET_MAPPING3 = 'AddressLine3';
    public static String COLLECTION_STREET_MAPPING1 = 'Col_add_1';
    public static String COLLECTION_STREET_MAPPING2 = 'Col_add_2';
    public static String COLLECTION_STREET_MAPPING3 = 'Col_add_3';
    public static String PARENT_ID_LOCATION_MAPPING = 'Account_Id';
    public static String ORDER_ID_MAPPING = 'Order_Id';
    public static String ORDER_EFFECTIVE_DATE_MAPPING = 'Order_Date';
    public static String ORDER_DELIVERY_DATE_MAPPING = 'Delivery_Date';
    public static String ORDER_INV_SERV_NOTE_DATE = 'Inv/Serv Note Date';

    public static String ORDER_LOCATION_ID_MAPPING = 'Location_Id';
    public static String ORDER_LINE_PRODUCT_ID_MAPPING = 'Product_Id';

    public static String ACCOUNT_RECORD_GROUP = 'Account';
    public static String LOCATION_RECORD_GROUP = 'Location';
    public static String ORDER_RECORD_GROUP = 'Order';
    public static String ORDER_LINE_RECORD_GROUP = 'OrderLine';
    public static String PRODUCT_RECORD_GROUP = 'Product';



    @TestVisible private static Map<String, EnquixImportMappings__c> enquixImportMappings;

    public static Map<String, EnquixImportMappings__c> getEnquixImportMappings() {
        if(enquixImportMappings == null) {
            enquixImportMappings = enquixImportMappings__c.getAll();
        }
        return enquixImportMappings;
    }

}