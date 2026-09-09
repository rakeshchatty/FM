public class NewLocationController {

    //jira 1946 - Copy the value of the Industry field when creating a new Location, this field will now be required.
	@AuraEnabled
	public static string createLocationController(string recordId, List < string > fields) {
		try {
			Opportunity opp;
			Account newAcc = new Account();
			opp = [select Id, Account.Id, Account.Name, Account.BillingStreet, Account.BillingCity, Account.BillingState, Account.BillingCountry, Account.BillingPostalCode, Account.RecordTypeId, Industry__c
				from Opportunity where Id =: recordId
			];
			newAcc.Name = fields[0];
			newAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
			newAcc.BillingCity = opp.Account.BillingCity;
			newAcc.BillingCountry = opp.Account.BillingCountry;
			newAcc.BillingPostalCode = opp.Account.BillingPostalCode;
			newAcc.BillingState = opp.Account.BillingState;
			newacc.BillingStreet = opp.Account.BillingStreet;
			newAcc.ParentId = opp.Account.Id;
			newAcc.Opportunity__c = opp.Id;
            newAcc.Industry = opp.Industry__c;
			insert newAcc;
			return newAcc.Id;
		} catch (Exception e) {
			system.debug(e.getMessage());
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string createLocationWithFields(string recordId, List < string > fields) {
		try {
			Opportunity opp = [select Id, Account.Id, Industry__c from Opportunity where Id =: recordId];
			Account newAcc = new Account();
			newAcc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();
			newAcc.Name = fields[0];
			newAcc.BillingStreet = fields[1];
			newAcc.BillingCity = fields[2];
			newAcc.BillingPostalCode = fields[3];
			newAcc.BillingState = fields[4];
			newAcc.BillingCountry = fields[5];
			newAcc.ParentId = opp.Account.Id;
			newAcc.Opportunity__c = opp.Id;
            newAcc.Industry = opp.Industry__c;
			insert newAcc;
			return newAcc.Id;
		} catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}

	@AuraEnabled
	public static string[] getParentLocName(string recordId) {
		try {
			Opportunity opp = [select Account.Name, Industry__c from Opportunity where Id = :recordId];
			List<string> fields = new List<string>();
			fields.add(opp.Account.Name);
			fields.add('');
			fields.add('');
			fields.add('');
			fields.add('');
			fields.add('');
			return fields;
		}
		catch (Exception e) {
			throw new AuraHandledException(e.getMessage());
		}
	}
}