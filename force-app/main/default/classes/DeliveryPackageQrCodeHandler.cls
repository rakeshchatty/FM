public without sharing class DeliveryPackageQrCodeHandler {

	public void handleTrigger(List<DeliveryPackageQrCode__c> newList, Map<Id, DeliveryPackageQrCode__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when BEFORE_INSERT{
				verifyDuplicates(newList);
			}
			when AFTER_INSERT {
				createQrCodeItems(newList);
			}
		}
	}

	private void verifyDuplicates(List<DeliveryPackageQrCode__c> newList) {
		for (DeliveryPackageQrCode__c packageQrCode : newList) {
			if (!DeliveryPackageQrCode.verifyDuplicates(new List<String>{packageQrCode.Code__c}).isEmpty()) {
				packageQrCode.Code__c.addError('Duplicate QR Code.');
			}
		}
	}

	private void createQrCodeItems(List<DeliveryPackageQrCode__c> newList) {
		List<DeliveryPackageQrCodeItem__c> packageQrCodeItems = new List<DeliveryPackageQrCodeItem__c>();

		for (DeliveryPackageQrCode__c packageQrCode : newList) {
			Set<String> individualQrCodes = DeliveryPackageQrCode.toIndividual(new List<String>{packageQrCode.Code__c});
			for (String individualQrCode : individualQrCodes) {
				packageQrCodeItems.add(new DeliveryPackageQrCodeItem__c(DeliveryPackageQrCode__c = packageQrCode.Id, Name = individualQrCode));
			}
		}

		if (!packageQrCodeItems.isEmpty()) {
			INSERT packageQrCodeItems;
		}
	}
}