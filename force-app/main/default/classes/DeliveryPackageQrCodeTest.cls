@isTest
private class DeliveryPackageQrCodeTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertSupplier('First Mile Ltd');
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);
		Product2 product = TestDataHelper.insertProduct('Test Name', 'Test Code', 'Delivery');
		PricebookEntry pbe = TestDataHelper.insertStandardPricebookEntry(product.Id, 65.00);
		TestDataHelper.insertOrderItem(order.Id, product.Id, pbe.Id);
		TestDataHelper.insertDeliveryPackage(order.Id, DeliveryPackage.STATUS_PACKAGED);
	}

	@isTest
	static void toIndividual() {
		Set<String> qrCodes = DeliveryPackageQrCode.toIndividual(new List<String>{'ABC123','ABC123,XYZ456','PQR789-DEF111'});
	 	Assert.areEqual(4, qrCodes.size());
		Assert.isTrue(qrCodes.contains('ABC123'));
		Assert.isTrue(qrCodes.contains('XYZ456'));
		Assert.isTrue(qrCodes.contains('PQR789'));
		Assert.isTrue(qrCodes.contains('DEF111'));
	}

	@isTest
	static void verifyDuplicates() {
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c LIMIT 1];
		OrderItem orderItem = [SELECT Id FROM OrderItem LIMIT 1];

		TestDataHelper.insertDeliveryPackageQrCode(pkg.Id, orderItem.Id, 'VERIFY001');
		List<String> duplicates = DeliveryPackageQrCodeDuplicateRest.doPost(new List<String>{'VERIFY001'});
		Assert.areEqual(1, duplicates.size());
		Assert.areEqual('VERIFY001', duplicates[0]);

		duplicates = DeliveryPackageQrCodeDuplicateRest.doPost(new List<String>{'VERIFY002'});
		Assert.areEqual(0, duplicates.size());

		duplicates = DeliveryPackageQrCodeDuplicateRest.doPost(new List<String>{'', null});
		Assert.areEqual(0, duplicates.size());

		INSERT new Qr_code__c(Driver_app_QR_code__c = 'QR001');
		duplicates = DeliveryPackageQrCodeDuplicateRest.doPost(new List<String>{'QR001'});
   	 	Assert.areEqual(1, duplicates.size());
		Assert.areEqual('QR001', duplicates[0]);
	}

	@isTest
	static void failDueToDuplicate() {
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c LIMIT 1];
		OrderItem orderItem = [SELECT Id FROM OrderItem LIMIT 1];

		TestDataHelper.insertDeliveryPackageQrCode(pkg.Id, orderItem.Id, 'DUPLICATE001');
		Test.startTest();
		try {
			TestDataHelper.insertDeliveryPackageQrCode(pkg.Id, orderItem.Id, 'DUPLICATE001');
			Assert.fail('Expected duplicate QR code error.');
		} catch (DmlException ex) {
			Assert.isTrue(ex.getMessage().contains('Duplicate QR Code.'));
		}
		Test.stopTest();
	}

	@isTest
	static void createItems(){
		DeliveryPackage__c pkg = [SELECT Id FROM DeliveryPackage__c LIMIT 1];
		OrderItem orderItem = [SELECT Id FROM OrderItem LIMIT 1];

		Test.startTest();
		DeliveryPackageQrCode__c qrCode = TestDataHelper.insertDeliveryPackageQrCode(pkg.Id, orderItem.Id, 'ABC123, XYZ456, PQR789');
		Test.stopTest();

		List<DeliveryPackageQrCodeItem__c> items = [SELECT Name FROM DeliveryPackageQrCodeItem__c WHERE DeliveryPackageQrCode__c = :qrCode.Id];
		Assert.areEqual(3, items.size());
	}
}