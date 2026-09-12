@isTest
private class DeliveryPackageLabelControllerTest {

	@testSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertSupplierFirstMile();
		TestDataHelper.insertOrder(location.Id);
	}

	@isTest
	static void render() {
		Order order = [SELECT Id FROM Order LIMIT 1];
		DeliveryPackage__c pkg = new DeliveryPackage__c(Order__c = order.Id, RequestedDeliveryDate__c = Date.Today());
		INSERT pkg;

		Test.startTest();
		pkg = new DeliveryPackageLabelController(new ApexPages.StandardController(pkg)).pkg;
		Test.stopTest();

		Assert.isNotNull(pkg.Order__r.OrderNumber);
		Assert.isNotNull(pkg.Order__r.Account.Name);
	}
}