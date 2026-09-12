public without sharing class PriceBookUtil {

	public static final Id STANDARD_PRICEBOOK_ID = [SELECT Id FROM Pricebook2 WHERE IsStandard = true].Id;
}