public without sharing class PutOutTimeController {

	// Method to fetch relevant Put Out Times
	@AuraEnabled(cacheable=true)
	public static List<Put_Out_Time__c> getRelevantPutOutTimes(Id accountId) {
		// Query the account to get its postcode and street
		Account account = [SELECT FirstPost__c, Street_Name__c FROM Account WHERE Id = :accountId LIMIT 1];

		// Return the matching Put Out Time records
		List<Put_Out_Time__c> putoutTimes = [SELECT Street_Name__c, Put_Out_Time__c FROM Put_Out_Time__c
			WHERE First_Post__c = :account.FirstPost__c AND Street_Name__c = :account.Street_Name__c
			ORDER BY Put_Out_Time__c];

		return putoutTimes.isEmpty() ? null : putoutTimes;
	}
}