public without sharing class AccountUtil {

	public static final Id RECORDTYPEID_PARENT	= Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
	public static final Id RECORDTYPEID_PARTNER = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Partner').getRecordTypeId();
	public static final Id RECORDTYPEID_LOCATION = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
	public static final Id RECORDTYPEID_PROSPECT = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Prospect').getRecordTypeId();

	public static final String PARTNER_TYPE_BID = 'BID';

	public static final String LIVE = 'Live';

	public static Boolean isLive(Account account) {
		return account.Enqix_Dead_Live__c == LIVE;
	}
	
	public static Boolean isPartner(Account account) {
		return account.RecordTypeId == RECORDTYPEID_PARTNER;
	}

	public static Boolean isFrequencyOverridden(Account location) {
		return String.isNotBlank(location.InvoiceFrequency__c);
	}

	public static Map<String, Account_Discount__c> getDiscounts(Set<Id> accountIds, Set<Id> productIds) {
		accountIds.remove(null);
		productIds.remove(null);
		List<Account_Discount__c> discounts = [SELECT Account__c, Product__c, Product_Discount__c, Bid_Price__c FROM Account_Discount__c 
			WHERE Account__c IN :accountIds AND Product__c IN :productIds 
			AND (DiscountSupStartDate__c <= TODAY OR DiscountSupStartDate__c = null) 
			AND (DiscountSupEndDate__c >= TODAY OR DiscountSupEndDate__c = null)];

		Map<String, Account_Discount__c> discountMap = new Map<String, Account_Discount__c>();
		for (Account_Discount__c discount : discounts) {
			discountMap.put(discount.Account__c + '-' + discount.Product__c, discount);
		}
		return discountMap;
	}
}