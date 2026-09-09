@isTest
private class DeliveryPackageAttachQrCodeTest {

	@isTest
	static void attach() {
		TestDataHelper.insertSupplier('First Mile Ltd');
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		Product2 product = TestDataHelper.insertProduct('Test Name', 'Test Code', 'Delivery');
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
		OrderItem orderItem = TestDataHelper.insertOrderItem(order.Id, product.Id, pbe.Id);
		DeliveryPackage__c pkg = TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_LABELLED);

		List<String> qrCodes = new String[] {'XYZ', 'ABC', 'PQR'};
		DeliveryPackageQrCode__c qrCode1 = TestDataHelper.createDeliveryPackageQrCode(pkg.Id, orderItem.Id, qrCodes[0]);
		DeliveryPackageQrCode__c qrCode2 = TestDataHelper.createDeliveryPackageQrCode(pkg.Id, orderItem.Id, qrCodes[1]);
		DeliveryPackageQrCode__c qrCode3 = TestDataHelper.createDeliveryPackageQrCode(pkg.Id, orderItem.Id, qrCodes[2]);
		INSERT new DeliveryPackageQrCode__c[]{qrCode1, qrCode2, qrCode3};

		Test.startTest();
		DeliveryPackageAttachQrCode.attach(new Id[]{order.id});
		Test.stopTest();

		qrCodes.sort();
		orderItem = [SELECT detrack_Qrcode__c FROM OrderItem LIMIT 1];
		Assert.areEqual(String.join(qrCodes, ','), orderItem.detrack_Qrcode__c);
	}
}