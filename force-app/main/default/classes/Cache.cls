/******************************************************************************************************************************
* Name - Cache
* Description
* - This class does the following:
* - creates a static map of all existing RecordTypes and stores them by sObjectAPIName.RecordTypeDeveloperName => Id
* Modification Log :
* ---------------------------------------------------------------------------
* Developer Date Description
* ---------------------------------------------------------------------------
* Zoran Zunko 05/03/2015 Created.
******************************************************************************************************************************/
public with sharing class Cache {
    private static Map<String,String> mRecordTypes;

    static {
        string Key;
        string Value;

        if (mRecordTypes==null) {
            List<RecordType>  rtlist=[select Id,Name, DeveloperName, SObjectType from RecordType];

            mRecordTypes = new Map<String,String>();

            for (RecordType rt : rtlist) {
                Key = rt.SObjectType + '.' + rt.DeveloperName;
                Value=rt.Id;

                mRecordTypes.put(Key ,Value );
            }
        }
    }

    public static string RecordTypeId(string RecordTypeName) {
        string result='';

        if (mRecordTypes.containsKey(RecordTypeName)) {
            result=mRecordTypes.get(RecordTypeName);
        }

        return  result;
    }
}