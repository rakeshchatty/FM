@isTest
public with sharing class ContactTriggerTest {

	public static testmethod void UnitTest(){
		Account acc = TestDataHelper.createAccount();
		acc.InvoiceFrequency__c = 'Monthly';
		INSERT acc;
		Contact novo = new Contact(LastName='teste', AccountId = acc.Id, Email = 'cerm@xpand-it.com');
		INSERT novo;

		system.debug('Inserido novo Contacto.');
		novo.Email = 'novo@xpand-it.com';
		update novo;
		Contact este = [SELECT LastName, previous_email__c, Email FROM Contact WHERE LastName = 'teste'];
		system.debug('Feito o update to contacto... vamos ver o previous email agora:' + este.previous_email__c + '. E o novo é: '+este.Email);

	}
}