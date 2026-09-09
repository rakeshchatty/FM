public without sharing class DeliveryPackageAttachQrCode {

	@InvocableMethod(label='Update QR Codes into Order Items')
	public static void attach(List<Id> orderIds) {
		List<OrderItem> orderItems = [SELECT detrack_Qrcode__c, (SELECT Code__c FROM QrCodes__r) FROM OrderItem WHERE OrderId IN :orderIds];
		for (OrderItem orderItem : orderItems) {
			List<String> detractQrCodes = new List<String>();
			for (DeliveryPackageQrCode__c qrCode : orderItem.QrCodes__r) {
				detractQrCodes.add(qrCode.Code__c.replace('-', ','));
			}
			detractQrCodes.sort();
			orderItem.detrack_Qrcode__c = String.join(detractQrCodes, ',');
		}
		UPDATE orderItems;
	}
}