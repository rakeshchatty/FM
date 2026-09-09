public class AccountDiscountTriggerHandler {
		
		/*
		 * aaaa-mm-dd / JIRA XXXX -> 1st version of duplicate discounts (same account and same Product)
		 * 2019-03-22 / JIRA 1487 -> redefinition of the duplicate validation (same account and same product cannot overlap in time)
		 */
		public static void handleBeforeInsert(List<Account_Discount__c> discs) {
			Set<Id> accountIDs = new Set<ID>();
			Set<Id> productIDs = new Set<ID>();
			for(Account_Discount__c accountDiscount : discs)
			{
				accountIDs.add(accountDiscount.Account__c);
				productIDs.add(accountDiscount.Product__c);
			}

			List<Account_Discount__c> currentADs = [SELECT Id, Product__c, Account__c, DiscountSupStartDate__c, DiscountSupEndDate__c FROM Account_Discount__c WHERE Account__c IN :accountIDs OR Product__c IN :productIDs];

			for (Account_Discount__c newAD : discs) {
				for (Account_Discount__c cad : currentADs) {
					if (newAD.Product__c == cad.Product__c && 
						newAD.Account__c == cad.Account__c && 
							(
									!( cad.DiscountSupEndDate__c != null && (newAD.DiscountSupEndDate__c < cad.DiscountSupStartDate__c || newAD.DiscountSupStartDate__c > cad.DiscountSupEndDate__c ) ) ||
                   cad.DiscountSupStartDate__c <= newAD.DiscountSupEndDate__c && cad.DiscountSupEndDate__c == null
								/*
								( cad.DiscountSupStartDate__c >= newAD.DiscountSupStartDate__c && cad.DiscountSupEndDate__c <= newAD.DiscountSupEndDate__c )|| 
								( cad.DiscountSupStartDate__c <= newAD.DiscountSupEndDate__c && cad.DiscountSupEndDate__c == null )*/
							)
						)
					{
						//newAD.addError('A discount for this product already exists.');
						newAD.addError('An account discount for this product and for  for this period already exist.');
					}
				}
			}
		}
}