@isTest
private class DeliveryPackageRestTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
        TestDataHelper.insertSupplier('First Mile Ltd');
		Order order = TestDataHelper.insertOrder(location.Id, Date.today());
	}
    
    @isTest
    static void getPackages() {
        Order order = [SELECT Id FROM Order LIMIT 1];
        DeliveryPackage__c pkg = TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_LABELLED);
        RestRequest req = new RestRequest();
        req.requestURI = '/services/apexrest/DeliveryPackageRest/' + Date.today();
        req.httpMethod = 'GET';
        RestContext.request = req;

        Assert.areEqual(DeliveryPackageRest.doGet().size(), 1);
    }

	@isTest
	static void lock() {
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_LABELLED);

		Assert.isNull(DeliveryPackageRest.lock(null), 'Null was expected');
		Assert.isNull(DeliveryPackageRest.lock(Date.today().addDays(3)), 'Null was expected');

		pkg = [SELECT Status__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_LABELLED, pkg.Status__c, 'Status should be ' + DeliveryPackage.STATUS_LABELLED);

		Id lockedDeliveryPackageId = DeliveryPackageRest.lock(Date.today());
		Assert.areEqual(pkg.Id, lockedDeliveryPackageId, 'Unexpected locked delivery package Id');

		pkg = [SELECT Status__c FROM DeliveryPackage__c WHERE Id = :pkg.Id];
		Assert.areEqual(DeliveryPackage.STATUS_LOCK, pkg.Status__c, 'Status should be ' + DeliveryPackage.STATUS_LOCK);

		Assert.isNull(DeliveryPackageRest.lock(Date.today()), 'Unexpected locked delivery package Id');
	}
}