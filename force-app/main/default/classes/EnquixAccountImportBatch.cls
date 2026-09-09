/**
* @author Zoran Zunko
* @date 10/22/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

global without sharing class EnquixAccountImportBatch implements Database.Batchable<String>, Database.Stateful {

    @TestVisible private Enqix_Import__c currentRecord;
    @TestVisible private Boolean headerProcessed;
    @TestVisible private Integer startRow;
    @TestVisible private String csvFile;
    @TestVisible private List<String> messages;
    @TestVisible private Map<String, Integer> headerIndexes;

    global EnquixAccountImportBatch() {

        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch .ctor - start');
        messages = new List<String>();

        headerProcessed = false;

        List<Enqix_Import__c> enqixImports = EquixImportManager.getPendingEnqixImports(EquixImportManager.IMPORT_TYPE_ACCOUNT);
        System.debug(LoggingLevel.DEBUG, 'enqixImports : ' + enqixImports);

        if (enqixImports.size() > 0) {

            currentRecord = enqixImports[0];
            currentRecord.Status__c = EquixImportManager.STATUS_IN_PROGRESS;
            update currentRecord;
        }

        System.debug(LoggingLevel.DEBUG, 'currentRecord: ' + currentRecord);
        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch .ctor - end');
    }

    global Iterable<String> start(Database.BatchableContext info) {

        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch start - start');
        messages.add('processing started...');

        try {

            if (currentRecord == null) {

                System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch start - end no records');
                return new List<String>();
            }
            else {

                Attachment att = EquixImportManager.getLatestAttachmentForEnqixImport(currentRecord.Id);
//                csvFile = att.Body.toString();
//                if (!csvFile.endsWith(Parser.CRLF)) {
//
//                    csvFile += Parser.CRLF;
//                }
                //csvFile = csvFile.subString(csvFile.indexOf(Parser.CRLF) + Parser.CRLF.length(), csvFile.length());
                System.debug('Final heap size: ' +  Limits.getHeapSize());

                System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch start - end processing');

                return new CSVIterator(att.Body.toString(), Parser.CRLF);
            }
        }
        catch (Exception ex) {

            System.debug(LoggingLevel.ERROR, ex.getMessage() + ' :: ' + ex.getStackTraceString());
            System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch start - end no attachment');
            messages.add(String.format('Error while parsing Enquix Import: {0}. Error details: {1}. Stack Trace: {2}', new List<String> {
                    currentRecord.Id, ex.getMessage(), ex.getStackTraceString()
            })) ;
            return new List<String>();
        }
    }

    global void execute(Database.BatchableContext info, List<String> scope) {

        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch execute - start');
        System.debug(LoggingLevel.DEBUG, 'scope.size(): ' + scope.size());
        //first create new csv from the scope lines
        String importFile = '';
        for (String row : scope) {

            importFile += row + Parser.CRLF;
        }

        List<List<String>> parsedData = new List<List<String>>();
        try {

            parsedData = CSVReader.readCSVFile(importFile);
        }
        catch (Exception ex) {

            messages.add(String.format('Error while parsing Enquix Import: {0}. Error details: {1}', new List<String> {
                    currentRecord.Id, ex.getStackTraceString()
            }));
            System.debug(LoggingLevel.ERROR, ex.getMessage() + '\n' + ex.getStackTraceString());

            return;
        }
        System.debug(LoggingLevel.DEBUG, 'parsedData.size(): ' + parsedData.size());
        //then process header if needed
        System.debug(LoggingLevel.DEBUG, 'headerProcessed: ' + headerProcessed);
        if (!headerProcessed) {

            headerIndexes = EquixImportManager.processHeader(parsedData[0]);
            headerProcessed = true;
            parsedData.remove(0);
        }

        List<Account> accounts = new List<Account>();
        Set<String> accountsEnqixIdSet = new Set<String>();

        for (List<String> csvLine : parsedData) {
            try{
                if (!accountsEnqixIdSet.contains(csvLine.get(headerIndexes.get(EnquixImportMappingsManager.PARENT_ID_LOCATION_MAPPING)))) {

                    accounts.add(AccountManager.createAccountRecordFromCSVLine(
                            csvLine
                            , EquixImportManager.getImportMappingMap().get(
                                    EquixImportManager.IMPORT_TYPE_ACCOUNT).get(
                                    EnquixImportMappingsManager.ACCOUNT_RECORD_GROUP)
                            , headerIndexes
                    ));

                    accountsEnqixIdSet.add(csvLine.get(headerIndexes.get(EnquixImportMappingsManager.PARENT_ID_LOCATION_MAPPING)));
                }
            }
            catch(Exception ex) {
                messages.add('The following error has occurred.\n' + ex.getStackTraceString() + ': ' + ex.getMessage() + '. Row causing the error:' + String.join(csvLine, ','));

                System.debug('The following error has occurred.');
                System.debug(ex.getStackTraceString() + ': ' + ex.getMessage());
                System.debug('Row causing the error:' + String.join(csvLine, ','));
            }


        }
        System.debug(LoggingLevel.DEBUG, 'accounts.size(): ' + accounts.size());

        Database.UpsertResult[] saveResults = Database.upsert(accounts, Account.Enqix_ID__c, false);
        Integer listIndex = 0; // We start at 2 because the CSV data starts in row 2

        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    messages.add('The following error has occurred.\n' + err.getStatusCode() + ': ' + err.getMessage() + '. Account fields that affected this error:\n ' + err.getFields() + '\NRow index : ' + listIndex+2);

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                    System.debug('The error was caused by the sobject at index: ' + listIndex);
                    System.debug(accounts.get(listIndex));

                }
            }
            listIndex++;
        }

        List<Account> locations = new List<Account>();

        for (List<String> csvLine : parsedData) {

            locations.add(AccountManager.createLocationRecordFromCSVLine(
                    csvLine
                    , EquixImportManager.getImportMappingMap().get(
                            EquixImportManager.IMPORT_TYPE_ACCOUNT).get(
                            EnquixImportMappingsManager.LOCATION_RECORD_GROUP)
                    , headerIndexes
            ));
        }
        System.debug(LoggingLevel.DEBUG, 'locations.size(): ' + locations.size());

        saveResults = Database.upsert(locations, Account.Enqix_Location_ID__c, false);
        listIndex = 0; // We start at 2 because the CSV data starts in row 2

        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    messages.add('The following error has occurred.\n' + err.getStatusCode() + ': ' + err.getMessage() + '. Account fields that affected this error:\n ' + err.getFields() + '\NRow index : ' + listIndex+2);

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Account fields that affected this error: ' + err.getFields());
                    System.debug('The error was caused by the sobject at index: ' + listIndex);
                    System.debug(locations.get(listIndex));
                }
            }
            listIndex++;
        }

        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch execute - end');
    }

    global void finish(Database.BatchableContext info) {

        if (currentRecord != null) {

            messages.add('Processing completed');
            currentRecord.Log__c = String.join(messages, '\n');

            if(currentRecord.Log__c.length() > EquixImportManager.getLogFieldLength()) {

                currentRecord.Log__c = currentRecord.Log__c.abbreviate(EquixImportManager.getLogFieldLength());
            }

            if(currentRecord.Log__c.contains('error')) {

                currentRecord.Status__c = EquixImportManager.STATUS_ERROR;
            }
            else {

                currentRecord.Status__c = EquixImportManager.STATUS_COMPLETED;
            }

            update currentRecord;
        }

        if (!Test.isRunningTest()) {

            if (EquixImportManager.getPendingEnqixImports(EquixImportManager.IMPORT_TYPE_ACCOUNT).size() > 0) {

                EnquixAccountImportBatch.batchMe();
            }
            else {

                EnquixOrderImportBatch.batchMe();
            }
        }
    }

    public static Boolean batchMe() {

        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch batchMe - start');
        Id jobId;
        if (!BatchUtility.accountBatchInstanceRunning()) {

            System.debug(LoggingLevel.DEBUG, 'Account_Batch_Size__c: ' + Integer.valueOf(EnqixImportCSVParametersManager.getCsvParameters().Account_Batch_Size__c));

            jobId = Database.executeBatch(new EnquixAccountImportBatch(), Integer.valueOf(EnqixImportCSVParametersManager.getCsvParameters().Account_Batch_Size__c));
        }

        System.debug(LoggingLevel.DEBUG, 'EnquixAccountImportBatch batchMe - end');
        return jobId != null;
    }

}