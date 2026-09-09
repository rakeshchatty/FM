/** 
(c) 2018 Xpand-IT
@date 11.2018 
@author Joao Gomes

@description Class created to test monitoring exception

@modifications 12.2018 - Exceptional Monotoring implementation
*/
@isTest
private class LogRegisterScheduleTester {
	
	@isTest static void test_method_one()
	{
        Integer totalErrorLogs = 0;
		Integer totalSucessLogs = 0;
		Datetime successDeleteDate = Datetime.now().addDays(-9);
		Datetime errorDeleteDate = Datetime.now().addDays(-32);
		Double successRate = 0.5;
		//Cron Expression syntax : “Seconds Minutes Hours Day_of_month Month Day_of_week optional_year”
        String CRON_EXP = '0 0 12 12 12 ? *';
        // Create test data
		List<Log__c> logs = new List<Log__c>();

		for (Integer i = 0; i <= 100; i++)
		{
			Log__c log = new Log__c();
			log.Action__c = 'Insert';
			log.Error_Message__c = 'This a log record for test coverage.';
			log.Object_Type__c = 'Contact';
			log.Parent_Info__c = 'Account';
			log.Process__c = 'Log Register Test Coverage';
			Double currentRate = Math.Random();
			System.debug('Success rate: ' + currentRate);
			if (currentRate <= successRate)
			{
				log.Is_Error__c = false;
				log.Record_ID__c = '00000000';
				log.CreatedDate = successDeleteDate;
				totalSucessLogs++;
			}
			else
			{
				log.Is_Error__c = true;
				log.Record_ID__c = '';
				log.CreatedDate = errorDeleteDate;
			   	totalErrorLogs++;
			}
			logs.add(log);
		}
        insert logs;
		system.debug(logs);
		List<Log__c> logsToUpd = [SELECT Id, Is_Error__c, CreatedDate FROM Log__c];
		for(Log__c log : logsToUpd)
		{
			if(log.Is_Error__c = true)
				Test.setCreatedDate(log.id, errorDeleteDate);
			else
				Test.setCreatedDate(log.id, successDeleteDate);
		}
		update logsToUpd;
		System.debug(logsToUpd);
		List<Log__c> debugErrorLogs = [SELECT Id, Is_Error__c, CreatedDate FROM Log__c WHERE Is_Error__c = true];
		List<Log__c> debugSuccessLogs = [SELECT Id, Is_Error__c, CreatedDate FROM Log__c WHERE Is_Error__c = false];
		System.debug(debugErrorLogs);
		System.debug(debugSuccessLogs);

        // Add assert here to validate result
		/*Integer expectedValue = 0;
		Datetime errorDateToDelete =  Datetime.now().addDays(-31);
		Datetime sucesseDateToDelete = Datetime.now().addDays(-8);
		Integer actualErrors = [Select count() From Log__c where CreatedDate < :errorDateToDelete AND Is_Error__c = true];
		Integer actualSuccess = [Select count() From Log__c where CreatedDate < :sucesseDateToDelete AND Is_Error__c = false];
		System.assertEquals(expectedValue, actualErrors, 'Error Log still Exists');
		System.assertEquals(expectedValue, actualSuccess, 'Success Log still Exists');
		system.debug('Error status: '+actualErrors+'/'+totalErrorLogs);
		system.debug('Error status: '+actualSuccess+'/'+totalSucessLogs);*/
	}
	
}