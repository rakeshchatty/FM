public without sharing class AcrUtil {

	public final static String FINANCE_ROLE = 'Finance Contact';
	public final static String SERVICE_ROLE = 'Service Contact';

	public static Contact getLatestServiceContactForPhone(Id accountId) {
		try {
			return [SELECT Contact.Name, Contact.Phone, Contact.MobilePhone FROM AccountContactRelation
				WHERE IsActive = true AND AccountId = :accountId AND (Contact.Phone != null OR Contact.MobilePhone != null)
				AND Roles INCLUDES (:SERVICE_ROLE)
				ORDER BY LastModifiedDate DESC LIMIT 1].Contact;
		} catch (QueryException e) {
			throw new NoAccountRoleException('No Service Contact found on this Account.');
		}
	}

	public static List<AccountContactRelation> getFinanceContactRelation(Set<Id> accountIds) {
		return [SELECT AccountId, Contact.Name, Contact.Email, Portal_Link__c FROM AccountContactRelation
			WHERE IsActive = true AND AccountId IN :accountIds AND Contact.Email != null
			AND Roles INCLUDES (:FINANCE_ROLE)
			AND Contact.Preferences__c IN ('Finance Only', 'Standard')];
	}


	private class NoAccountRoleException extends Exception {}
}