@istest
private class TestSplitQRCodesIntoNewRecords {

	@istest
	static void TestAddDetrackQRCodesRecord() {
		List<QR_Codes_from_Detrack__c> codesFromDetrack = new List<QR_Codes_from_Detrack__c>();
		codesFromDetrack.add(new QR_Codes_from_Detrack__c());
		codesFromDetrack.add(new QR_Codes_from_Detrack__c(QR_Codes_from_OrderItem__c = 'ABC'));
		codesFromDetrack.add(new QR_Codes_from_Detrack__c(QR_Codes_from_OrderItem__c = 'ABC,XYZ'));
		codesFromDetrack.add(new QR_Codes_from_Detrack__c(QR_Codes_from_OrderItem__c = ',,ABC,,XYZ,,'));
		codesFromDetrack.add(new QR_Codes_from_Detrack__c(QR_Codes_from_OrderItem__c = 'ABC-XYZ'));
		codesFromDetrack.add(new QR_Codes_from_Detrack__c(QR_Codes_from_OrderItem__c = '--ABC--XYZ--'));
		codesFromDetrack.add(new QR_Codes_from_Detrack__c(QR_Codes_from_OrderItem__c = '--pQr--uvw,KlM--'));

		Test.startTest();
		INSERT codesFromDetrack;
		Test.stopTest();

		Map<Id, QR_Codes_from_Detrack__c> codesMap = new Map<Id, QR_Codes_from_Detrack__c>([SELECT Number_of_codes__c, QR_Codes_from_OrderItem__c FROM QR_Codes_from_Detrack__c]);
		Assert.areEqual(0, codesMap.get(codesFromDetrack[0].Id).Number_of_codes__c);
		Assert.areEqual(1, codesMap.get(codesFromDetrack[1].Id).Number_of_codes__c);
		Assert.areEqual(2, codesMap.get(codesFromDetrack[2].Id).Number_of_codes__c);
		Assert.areEqual(2, codesMap.get(codesFromDetrack[3].Id).Number_of_codes__c);
		Assert.areEqual(2, codesMap.get(codesFromDetrack[4].Id).Number_of_codes__c);
		Assert.areEqual(2, codesMap.get(codesFromDetrack[5].Id).Number_of_codes__c);
		Assert.areEqual(3, codesMap.get(codesFromDetrack[6].Id).Number_of_codes__c);

		List<Qr_code__c> qrCodes = [SELECT Driver_app_QR_code__c FROM Qr_code__c];
		Assert.areEqual(5, qrCodes.size());
		for (Qr_code__c qrCode : qrCodes) {
			Assert.isTrue(qrCode.Driver_app_QR_code__c.isAllUpperCase());
		}
	}
}