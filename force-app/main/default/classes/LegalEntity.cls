public without sharing class LegalEntity {

	public static LegalEntity__c get(Id id) {
		return [SELECT Name, Logo__c, Website__c, AddressFull__c, Phone__c, RegistrationNumber__c, VatNumber__c, AccountsEmail__c, 
				BankAccountNumber__c, BankSortCode__c, TermsOfService__c, BIC__c, IBAN__c
				FROM LegalEntity__c WHERE Id = :id];
	}
}