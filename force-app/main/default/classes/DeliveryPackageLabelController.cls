public without sharing class DeliveryPackageLabelController {

	public DeliveryPackage__c pkg { get; private set; }

	public DeliveryPackageLabelController(ApexPages.StandardController ctrl) {
		//pkg = [SELECT Id, Order__r.OrderNumber FROM DeliveryPackage__c WHERE Id = :ctrl.getId()];
		pkg = [SELECT Id, Order__r.OrderNumber, Order__r.Account.Name,
			Order__r.ShippingStreetLineSingle__c, Order__r.ShippingCity, Order__r.ShippingPostalCode,
			Order__r.Account.Enqix_Dly_ExtraInfo__c
			//FROM DeliveryPackage__c WHERE Id = 'a0TPv000009eJYDMA2'];
			FROM DeliveryPackage__c WHERE Id = :ctrl.getId()];
	}
}