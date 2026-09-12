public without sharing class DeliveryPackageQrCode {

	public static List<String> verifyDuplicates(List<String> qrCodes) {
		Set<String> individualQrCodes = toIndividual(qrCodes);
		if (individualQrCodes.isEmpty()) {
			return new List<String>();
		}

		Set<String> duplicates = new Set<String>();

		List<Qr_code__c> duplicateQrCodes = [SELECT Driver_app_QR_code__c FROM Qr_code__c WHERE Driver_app_QR_code__c IN :individualQrCodes];
		for (Qr_code__c duplicateQrCode : duplicateQrCodes) {
			duplicates.add(duplicateQrCode.Driver_app_QR_code__c);
		}
		individualQrCodes.removeAll(duplicates);

		List<DeliveryPackageQrCodeItem__c> duplicateItems = [SELECT Name FROM DeliveryPackageQrCodeItem__c WHERE Name IN :individualQrCodes
			AND DeliveryPackageQrCode__r.DeliveryPackage__r.Status__c IN ('Packaged', 'In Progress')];
		for (DeliveryPackageQrCodeItem__c duplicateItem : duplicateItems) {
			duplicates.add(duplicateItem.Name);
		}

		return new List<String>(duplicates);
	}

	public static Set<String> toIndividual(List<String> qrCodes) {
		Set<String> individualQrCodes = new Set<String>();

		for (String qrCode : qrCodes) {
			if (String.isBlank(qrCode)) {
				continue;
			}
			individualQrCodes.addAll(StringUtil.splitTrim(qrCode.toUpperCase().replace('-', ','), ','));
		}

		return individualQrCodes;
	}
}