/**
* @author Zoran Zunko
* @date 10/22/15
*
* @group 
* @group-content ../../ApexDocContent/
*
* @description 
*/

global without sharing class EnquixOrderImportBatch implements Database.Batchable<String>, Database.Stateful {

    @TestVisible private Enqix_Import__c currentRecord;
    @TestVisible private Boolean headerProcessed;
    @TestVisible private Integer startRow;
    @TestVisible private String csvFile;
    @TestVisible private List<String> messages;
    @TestVisible private Map<String, Integer> headerIndexes;

    global EnquixOrderImportBatch() {

        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch .ctor - start');
        messages = new List<String>();

        headerProcessed = false;

        List<Enqix_Import__c> enqixImports = EquixImportManager.getPendingEnqixImports(EquixImportManager.IMPORT_TYPE_ORDER);
        System.debug(LoggingLevel.DEBUG, 'enqixImports : ' + enqixImports);

        if (enqixImports.size() > 0) {

            currentRecord = enqixImports[0];
            currentRecord.Status__c = EquixImportManager.STATUS_IN_PROGRESS;
            update currentRecord;
        }

        System.debug(LoggingLevel.DEBUG, 'currentRecord: ' + currentRecord);
        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch .ctor - end');
    }

    global Iterable<String> start(Database.BatchableContext info) {

        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch start - start');
        messages.add('processing started...');

        try {

            if (currentRecord == null) {

                System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch start - end no records');
                return new List<String>();
            }
            else {

                Attachment att = EquixImportManager.getLatestAttachmentForEnqixImport(currentRecord.Id);
                if (att.Body.toString().length() > 12000000) {
                    throw new EnquixImportException('File size cannot exceed 12m characters');
                }
                csvFile = att.Body.toString();
                if (!csvFile.endsWith(Parser.CRLF)) {

                    csvFile += Parser.CRLF;
                }

                System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch start - end processing');

                return new CSVIterator(csvFile, Parser.CRLF);
            }
        }
        catch (Exception ex) {

            System.debug(LoggingLevel.ERROR, ex.getMessage() + ' :: ' + ex.getStackTraceString());
            System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch start - end no attachment');
            messages.add(String.format('Error while parsing Enquix Import: {0}. Error details: {1}. Stack Trace: {2}', new List<String> {
                    currentRecord.Id, ex.getMessage(), ex.getStackTraceString()
            })) ;
            return new List<String>();
        }
    }

    global void execute(Database.BatchableContext info, List<String> scope) {

        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch execute - start');
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

            messages.add(String.format('Error while parsing Enquix Import: {0}. Error details: {1}. Stack Trace: {2}', new List<String> {
                    currentRecord.Id, ex.getMessage(), ex.getStackTraceString()
            })) ;
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

        List<Order> orders = new List<Order>();
        Set<String> ordersEnqixIdSet = new Set<String>();
        //todo check if already parsed the one with the enq id same on the locations and accounts
        //todo create products if they dont exist
        for (List<String> csvLine : parsedData) {

            if (!ordersEnqixIdSet.contains(csvLine.get(headerIndexes.get(EnquixImportMappingsManager.ORDER_ID_MAPPING)))) {

                orders.add(OrderManager.createOrderRecordFromCSVLine(
                        csvLine
                        , EquixImportManager.getImportMappingMap().get(
                                EquixImportManager.IMPORT_TYPE_ORDER).get(
                                EnquixImportMappingsManager.ORDER_RECORD_GROUP)
                        , headerIndexes
                ));

                ordersEnqixIdSet.add(csvLine.get(headerIndexes.get(EnquixImportMappingsManager.ORDER_ID_MAPPING)));
            }
        }
        System.debug(LoggingLevel.DEBUG, 'orders.size(): ' + orders.size());

        Database.UpsertResult[] saveResults = Database.upsert(orders, Order.Enqix_ID__c, false);
        Integer listIndex = 0; // We start at 2 because the CSV data starts in row 2

        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    messages.add('The following error has occurred.\n' + err.getStatusCode() + ': ' + err.getMessage() + ' - Order fields that affected this error:\n ' + err.getFields());

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Order fields that affected this error: ' + err.getFields());
                    System.debug('The error was caused by the sobject at index: ' + listIndex);
                    System.debug(orders.get(listIndex));
                }
            }
            listIndex++;
        }

        List<Product2> products = new List<Product2>();
        Set<String> productsEnqixIdSet = new Set<String>();
        for (List<String> csvLine : parsedData) {

            if (!productsEnqixIdSet.contains(csvLine.get(headerIndexes.get(EnquixImportMappingsManager.ORDER_LINE_PRODUCT_ID_MAPPING)))) {

                products.add(ProductManager.createProductRecordFromCSVLine(
                        csvLine
                        , EquixImportManager.getImportMappingMap().get(
                                EquixImportManager.IMPORT_TYPE_ORDER).get(
                                EnquixImportMappingsManager.PRODUCT_RECORD_GROUP)
                        , headerIndexes
                ));

                productsEnqixIdSet.add(csvLine.get(headerIndexes.get(EnquixImportMappingsManager.ORDER_LINE_PRODUCT_ID_MAPPING)));
            }
        }
        System.debug(LoggingLevel.DEBUG, 'products.size(): ' + products.size());

        saveResults = Database.upsert(products, Product2.Enqix_ID__c, false);
        listIndex = 0;

        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    messages.add('The following error has occurred.\n' + err.getStatusCode() + ': ' + err.getMessage() + ' - Product fields that affected this error:\n ' + err.getFields());

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Product fields that affected this error: ' + err.getFields());
                    System.debug('The error was caused by the sobject at index: ' + listIndex);
                    System.debug(products.get(listIndex));
                }
            }
            listIndex++;
        }

        Map<String, PricebookEntry> pricebookEntriesByProductEnqixIds = PricebookEntryManager.getPricebookEntriesByProductEnqixIds(new List<String>(productsEnqixIdSet));
        List<PricebookEntry> pbEntries = new List<PricebookEntry>();

        for (Product2 product : products) {

            if (pricebookEntriesByProductEnqixIds.get(product.Enqix_Id__c) == null) {

                PricebookEntry pbEntry = PricebookEntryManager.createStandardEntryFromProduct(product);
                pbEntries.add(pbEntry);
                pricebookEntriesByProductEnqixIds.put(product.Enqix_Id__c, pbEntry);
            }
        }


        saveResults = Database.upsert(pbEntries, false);
        listIndex = 0;

        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    messages.add('The following error has occurred.\n' + err.getStatusCode() + ': ' + err.getMessage() + ' - PriceBookEntry fields that affected this error:\n ' + err.getFields());

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('PriceBookEntry fields that affected this error: ' + err.getFields());
                    System.debug('The error was caused by the sobject at index: ' + listIndex);
                    System.debug(pbEntries.get(listIndex));
                }
            }
            listIndex++;
        }
        System.debug(LoggingLevel.DEBUG, 'pbEntries.size(): ' + pbEntries.size());

        List<OrderItem> orderLines = new List<OrderItem>();

        for (List<String> csvLine : parsedData) {

            orderLines.add(OrderLineManager.createOrderItemRecordFromCSVLine(
                    csvLine
                    , EquixImportManager.getImportMappingMap().get(
                            EquixImportManager.IMPORT_TYPE_ORDER).get(
                            EnquixImportMappingsManager.ORDER_LINE_RECORD_GROUP)
                    , headerIndexes
                    , pricebookEntriesByProductEnqixIds
            ));
        }
        System.debug(LoggingLevel.DEBUG, 'orderLines.size(): ' + orderLines.size());

        saveResults = Database.upsert(orderLines/*, Account.Enqix_ID__c*/, false);
        listIndex = 0;

        for (Database.UpsertResult sr : saveResults) {
            if (!sr.isSuccess()) {
                for (Database.Error err : sr.getErrors()) {
                    messages.add('The following error has occurred.\n' + err.getStatusCode() + ': ' + err.getMessage() + ' - OrderItem fields that affected this error:\n ' + err.getFields());

                    System.debug('The following error has occurred.');
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('OrderItem fields that affected this error: ' + err.getFields());
                    System.debug('The error was caused by the sobject at index: ' + listIndex);
                    System.debug(orderLines.get(listIndex));
                }
            }
            listIndex++;
        }

        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch execute - end');
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

            if (EquixImportManager.getPendingEnqixImports(EquixImportManager.IMPORT_TYPE_ORDER).size() > 0) {

                EnquixOrderImportBatch.batchMe();
            }

        }

    }

    public static Boolean batchMe() {

        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch batchMe - start');
        Id jobId;
        if (!BatchUtility.orderBatchInstanceRunning()) {

            System.debug(LoggingLevel.DEBUG, 'Orders_Batch_Size__c: ' + Integer.valueOf(EnqixImportCSVParametersManager.getCsvParameters().Orders_Batch_Size__c));
            jobId = Database.executeBatch(new EnquixOrderImportBatch(), Integer.valueOf(EnqixImportCSVParametersManager.getCsvParameters().Orders_Batch_Size__c));
        }

        System.debug(LoggingLevel.DEBUG, 'EnquixOrderImportBatch batchMe - end');
        return jobId != null;
    }

}