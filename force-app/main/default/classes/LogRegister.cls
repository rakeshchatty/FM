/**
(c) 2018 Xpand-IT
@date 11.2018
@author Bruno Mendes and Joao Gomes

@description Class created to populate the Log__c object

@modifications 12.2018 - Exceptional Monotoring implementation
*/
public with sharing class LogRegister {
	public String objectType {get; set;}
	public String process {get; set;}
	public String action {get; set;}
	public String recordId {get; set;}
	public String errorMessage {get; set;}

	public LogRegister(String objectType, String process, String action, String  recordId, String errorMessage) {
		this.objectType = objectType;
		this.process = process;
		this.action = action;
		this.recordId = recordId;
		this.errorMessage = errorMessage;
	}

	private static Log__c createLog(Boolean isSuccess, List<Database.Error> errors, Id recordId, sObject record, String process, String action, String sObjectType, String parentField) {
		Log__c log = new Log__c(Process__c = process, Action__c = action, Object_Type__c = sObjectType);

		String errorMessage = '';
		if (!String.isBlank(parentField) && record.get(parentField) != null) {
			ID parentId = (String) record.get(parentField);
			log.Parent_Info__c = 'Object Type "' + parentId.getSObjectType() + '" with ID "' + parentId + '"';
		}
		if (!isSuccess) {
			errorMessage = 'Error on ' + action + ' a record of '+ sObjectType + ' with the following data:\n' + record + '\n\n';
			errorMessage += 'Error List:\n';
			for (Database.Error err : errors) {
				errorMessage += 'The following error has occurred - ' + err.getStatusCode() + ': ' + err.getMessage() + ' Fields that affected this error: ' + err.getFields() + '\n';
			}
			log.Is_Error__c = true;
			log.Record_ID__c = '';
			log.Error_Message__c = errorMessage;
		}
		else {
			log.Record_ID__c = recordId;
		}

		return log;
	}

	public static void createLogs(List<Database.DeleteResult> results, List<sObject> records, String process, String action, String sObjectType, String parentField) {
		List<Log__c> logs = new List<Log__c>();
		try {
			for (Integer idx = 0; idx < results.size(); idx++) {
				logs.add(createLog(results[idx].isSuccess(), results[idx].getErrors(), results[idx].getId(), records[idx], process, action, sObjectType, parentField));
			}

			INSERT logs;
		}
		catch (Exception e) {
			System.debug(e.getMessage());
		}
	}

	public static void createLogsUpsert(List<Database.SaveResult> results, List<sObject> records, String process, String action, String sObjectType, String parentField) {
		List<Log__c> logs = new List<Log__c>();
		try {
            for (Integer idx = 0; idx < results.size(); idx++) {
                if (!results[idx].isSuccess()) {
                    logs.add(createLog(false, results[idx].getErrors(), results[idx].getId(), records[idx], process, action, sObjectType, parentField));
                }
            }

			INSERT logs;
		}
		catch (Exception e) {
			System.debug(e.getMessage());
		}
	}

	public static void createLogsUpsert(List<Database.UpsertResult> results, List<sObject> records, String process, String action, String sObjectType, String parentField) {
		List<Log__c> logs = new List<Log__c>();
		try {
            for (Integer idx = 0; idx < results.size(); idx++) {
                if (!results[idx].isSuccess()) {
                    logs.add(createLog(false, results[idx].getErrors(), results[idx].getId(), records[idx], process, action, sObjectType, parentField));
                }
            }

			INSERT logs;
		}
		catch (Exception e) {
			System.debug(e.getMessage());
		}
	}

	public static void createLogs(List<LogRegister> logs) {
		List<Log__c> logsToInsert = new List<Log__c>();
		for (LogRegister logreg : logs) {
			logsToInsert.add(new Log__c(Object_Type__c = logreg.objectType, Process__c = logreg.process, Action__c = logreg.action, Record_ID__c = logreg.recordId, Error_Message__c = logreg.errorMessage));
		}

		try {
			INSERT logsToInsert;
		}
		catch (Exception e) {
			system.debug('Error! - ' + e.getMessage());
		}
	}
}