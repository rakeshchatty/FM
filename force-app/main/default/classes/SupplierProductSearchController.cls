public with sharing class SupplierProductSearchController {

	@AuraEnabled(cacheable=true)
	public static List<SupplierProductWrapper> getSuppliersWithProduct(Id postcodeId, Id productId) {
		Set<Id> supplierIds = new Set<Id>();
		for (Postcode_Supplier__c ps : [SELECT Supplier__c FROM Postcode_Supplier__c WHERE Postcode__c = :postcodeId]) {
			supplierIds.add(ps.Supplier__c);
		}
		if (supplierIds.isEmpty()) {
			return new List<SupplierProductWrapper>();
		}

		List<Supplier_Product__c> matches = [SELECT Supplier__c, Product__c, Supplier_Price__c, Supplier__r.Name, End_Date__c, CurrencyIsoCode FROM Supplier_Product__c
			WHERE Product__c = :productId AND Supplier__c IN :supplierIds AND End_Date__c > TODAY
			ORDER BY Supplier_Price__c ASC];
		if (matches.isEmpty()) {
			throw new AuraHandledException('None of the suppliers in this area can offer this product - please check to see whether their Supplier Products are within date');
		}

		List<SupplierProductWrapper> results = new List<SupplierProductWrapper>();
		for (Supplier_Product__c sp : matches) {
			results.add(new SupplierProductWrapper(sp.Supplier__r.Name, sp.Supplier_Price__c, sp.CurrencyIsoCode));
		}

		return results;
	}

	@AuraEnabled(cacheable=true)
	public static List<Product2> searchProducts(String searchKey) {
		return [SELECT Id, Name FROM Product2 WHERE Name LIKE :('%' + searchKey + '%') ORDER BY Name LIMIT 10];
	}

	public class SupplierProductWrapper {
		@AuraEnabled public String supplierName;
		@AuraEnabled public Decimal supplierPrice;
		@AuraEnabled public String currencyIsoCode;

		public SupplierProductWrapper(String name, Decimal price, String currencyIsoCode) {
			this.supplierName = name;
			this.supplierPrice = price;
			this.currencyIsoCode = currencyIsoCode;
		}
	}
}