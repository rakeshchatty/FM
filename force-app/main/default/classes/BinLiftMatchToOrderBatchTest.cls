@isTest
private class BinLiftMatchToOrderBatchTest {

	@isTest
	static void test() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null, 'FM0001');

		BinLift__c bin1 = new BinLift__c(LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', ExternalId__c = '43FD4C14001', WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, CollectedAt__c = System.now() - 1);
		BinLift__c bin2 = new BinLift__c(LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', ExternalId__c = '43FD4C14002', WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, CollectedAt__c = System.now() - 1);
		BinLift__c bin3 = new BinLift__c(LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400004000', ExternalId__c = '43FD4C14003', WasteCategoryCode__c = 'GEN1100', Kilogram__c = 100, CollectedAt__c = System.now() - 3);
		BinLift__c bin4 = new BinLift__c(LocationCode__c = 'FM0001', TransponderCode__c = '43FD4C1400006000', ExternalId__c = '43FD4C14004', WasteCategoryCode__c = 'GEN1101', Kilogram__c = 100, CollectedAt__c = System.now() - 1);
		INSERT new List<BinLift__c>{bin1, bin2, bin3, bin4};

		Product2 product = TestDataHelper.insertProduct('General Collection', '123', 'Collection');
		product.BinCategoryCode__c = 'GEN1100';
		UPDATE product;

		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 1020);

		Order order = TestDataHelper.insertOrder(location.Id);
		OrderItem orderItem1 = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
        orderItem1.CollectionDate__c = Date.today() - 1;
		orderItem1.AllowedWeight__c = 70;
		INSERT orderItem1;

		OrderItem orderItem2 = TestDataHelper.createOrderItem(order.Id, product.Id, pbe.Id);
        orderItem2.CollectionDate__c = Date.today() - 5;
		INSERT orderItem2;

		Test.startTest();
		new BinLiftMatchToOrderScheduler().execute(null);
		Test.stopTest();

		Assert.areEqual(null, [SELECT OrderProduct__c FROM BinLift__c WHERE Id = :bin4.Id].OrderProduct__c);
		Assert.areEqual(orderItem1.Id, [SELECT OrderProduct__c FROM BinLift__c WHERE Id = :bin1.Id].OrderProduct__c);
		Assert.areEqual(orderItem1.Id, [SELECT OrderProduct__c FROM BinLift__c WHERE Id = :bin2.Id].OrderProduct__c);
		Assert.areEqual(2, [SELECT COUNT() FROM BinLift__c WHERE AllowedWeight__c = 70 AND OrderProduct__c = :orderItem1.Id]);
		Assert.areEqual(orderItem2.Id, [SELECT OrderProduct__c FROM BinLift__c WHERE Id = :bin3.Id].OrderProduct__c);
	}
}