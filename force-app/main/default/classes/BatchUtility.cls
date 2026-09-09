/**
* @author Zoran Zunko
* @date 10/22/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

public with sharing class BatchUtility {

    public static final String ACCOUNT_BATCH_CLASS = 'EnquixAccountImportBatch';
    public static final String ORDER_BATCH_CLASS = 'EnquixOrderImportBatch';

    @TestVisible static final List<String> batchStatusQueryList = new List<String> {
            'Holding'
            , 'Queued'
            , 'Preparing'
            , 'Processing'
    };

    public static Boolean accountBatchInstanceRunning() {

        return batchInstanceRunning(ACCOUNT_BATCH_CLASS);
    }

    public static Boolean orderBatchInstanceRunning() {

        return batchInstanceRunning(ORDER_BATCH_CLASS);
    }

    @TestVisible static Boolean batchInstanceRunning(String className) {

        System.debug(LoggingLevel.DEBUG, 'BatchUtility batchInstanceRunning - start');
        System.debug(LoggingLevel.DEBUG, 'className: ' + className);

        List<AsyncApexJob> existingApexJobs =
        [
                SELECT ApexClassID, ApexClass.Name, CompletedDate, JobType, Status
                FROM AsyncApexJob
                WHERE Status IN :batchStatusQueryList
                        AND ApexClass.Name = :className
                        AND JobType LIKE '%Batch%'
        ];
        System.debug(LoggingLevel.DEBUG, 'existingApexJobs.size(): ' + existingApexJobs.size());
        System.debug(LoggingLevel.DEBUG, 'BatchUtility batchInstanceRunning - end');

        return existingApexJobs.size() > 0;
    }

}