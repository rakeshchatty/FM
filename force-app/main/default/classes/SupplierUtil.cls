public without sharing class SupplierUtil {

	public static final Suppliers__c FIRST_MILE_SUPPLIER = [SELECT Id, Name FROM Suppliers__c WHERE IsExternal__c = false];
}