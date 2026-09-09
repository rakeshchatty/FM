@RestResource(urlMapping='/DeliveryPackage/*')
global without sharing class DeliveryPackageRest {

    @HttpGet
    global static List<sObject> doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        Date requestedDeliveryDate = date.valueOf(req.requestURI.substring(req.requestURI.lastIndexOf('/')+1));
        return [SELECT Id, OrderNumber, Account.Name, (SELECT Id, ProductName__c, Quantity, (SELECT Id FROM QrCodes__r) FROM OrderItems), (SELECT Id, Count__c, Carrier__c, Status__c, (SELECT Id FROM Attachments) FROM DeliveryPackages__r WHERE RequestedDeliveryDate__c = :requestedDeliveryDate ORDER BY CreatedDate DESC LIMIT 1) FROM Order WHERE Id IN (SELECT Order__c FROM DeliveryPackage__c WHERE Status__c IN ('Labelled', 'Packaged', 'Lock') AND RequestedDeliveryDate__c = :requestedDeliveryDate) ORDER BY OrderNumber LIMIT 50000];
    }

	@HttpPatch
	global static Id lock(Date requestedDate) {
		DeliveryPackage__c pkg;
		try {
			pkg = [SELECT Id FROM DeliveryPackage__c WHERE Status__c = :DeliveryPackage.STATUS_LABELLED AND RequestedDeliveryDate__c = :requestedDate LIMIT 1 FOR UPDATE];
		} catch (QueryException e) {
			return null;
		}

		pkg.Status__c = DeliveryPackage.STATUS_LOCK;
		UPDATE pkg;

		return pkg.Id;
	}
}