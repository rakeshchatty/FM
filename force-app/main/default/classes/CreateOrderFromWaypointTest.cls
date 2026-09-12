@isTest
private class CreateOrderFromWaypointTest {

	@testSetup
	static void makeData() {
		TestDataHelper.insertVat();

		Product2 collectionProduct = TestDataHelper.createProduct('Product 1', 'P0001', 'Collection');
		collectionProduct.Service_Type__c = 'BATTERIES';
		collectionProduct.Service_Subtype__c = 'Liquid';
		INSERT collectionProduct;
		TestDataHelper.insertStandardPricebookEntry(collectionProduct.Id, 10.00);
		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');
		Supplier_Product__c supplierProduct = TestDataHelper.insertSupplierProduct(supplier, collectionProduct);

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Round__c round = TestDataHelper.insertRound();
		INSERT new DailyDispatch__c(RoundId__c = round.Id, Name = 'Test dispatch');

		Facility__c facility = TestDataHelper.insertFacility('Facility');

		Case extraCase = new Case(
			RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Extra Job').getRecordTypeId(),
			Type = 'Extra Job',
			AccountId = location.Id,
			Location__c = location.Id,
			Supplier__c = supplier.Id,
			SupplierProduct__c = supplierProduct.Id,
			Facility__c = facility.Id
		);
		INSERT extraCase;
	}

	@isTest
	static void onCaseWithoutChargeProduct() {
		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c];
		Case extraCase = [SELECT Id FROM Case];
		extraCase.Quantity__c = 5;
		extraCase.Round_Dispatched__c = dispatch.Id;
		UPDATE extraCase;

		Collection_Waypoints__c waypoint = [SELECT Id FROM Collection_Waypoints__c];
		Test.startTest();
		CreateOrderFromExtraWaypoint.create(new List<Id>{waypoint.Id});
		Test.stopTest();

		Order extrOrder = [SELECT Id, Quantity__c, (SELECT Id, TotalPrice FROM OrderItems) FROM Order];
		Assert.areEqual(1, extrOrder.OrderItems.size());
		Assert.areEqual(5, extrOrder.Quantity__c);
		Assert.areEqual(50, extrOrder.OrderItems[0].TotalPrice);
	}

	@isTest
	static void onCaseWithChargeProduct() {
		Product2 chargeProduct = TestDataHelper.insertProduct('Product 2', 'P0002', 'Collection');
		TestDataHelper.insertStandardPricebookEntry(chargeProduct.Id, 5.00);

		DailyDispatch__c dispatch = [SELECT Id FROM DailyDispatch__c];
		Case extraCase = [SELECT Id FROM Case];
		extraCase.CalloutChargeProduct__c = chargeProduct.Id;
		extraCase.Round_Dispatched__c = dispatch.Id;
		UPDATE extraCase;

		Collection_Waypoints__c waypoint = [SELECT Id FROM Collection_Waypoints__c];
		Test.startTest();
		CreateOrderFromExtraWaypoint.create(new List<Id>{waypoint.Id});
		Test.stopTest();

		Order extrOrder = [SELECT Id, Quantity__c, (SELECT Id, TotalPrice FROM OrderItems) FROM Order];
		Decimal totalPrice = 0;
		for (OrderItem orderItem : extrOrder.OrderItems) {
			totalPrice += orderItem.TotalPrice;
		}
		Assert.areEqual(2, extrOrder.OrderItems.size());
		Assert.areEqual(2, extrOrder.Quantity__c);
		Assert.areEqual(15, totalPrice);
	}
}