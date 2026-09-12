@RestResource(urlMapping='/ProcessAdditionCharges/')
global without sharing class AdditionalCharges {

	global class OrderData {
		@AuraEnabled public Id locationId { get; set; }
		@AuraEnabled public List<OrderItemData> orderItems { get; set; }
	}

	global class OrderItemData {
		@AuraEnabled public Id productId { get; set; }
		@AuraEnabled public Decimal quantity { get; set; }
		@AuraEnabled public Decimal unitPrice { get; set; }
		@AuraEnabled public Id pricebookEntryId { get; set; }
		@AuraEnabled public String productName { get; set; }
		@AuraEnabled public Decimal vatRate { get; set; }
	}

	public static List<OrderItemData> process(OrderData orderData) {
		List<OrderItemData> additionalCharges = new List<OrderItemData>();
		AdditionalChargesImpl additionChargesImpl = new AdditionalChargesImpl();
		additionalCharges.addAll(additionChargesImpl.addFuelSurcharge(orderData));
		additionalCharges.addAll(additionChargesImpl.addDeliveryCharge(orderData, additionalCharges));
		additionalCharges.addAll(additionChargesImpl.addWTNCharge(orderData));

		return additionalCharges;
	}

	@HttpPost
	global static List<OrderItemData> process() {
		OrderData orderData = (OrderData)JSON.deserialize(RestContext.request.requestBody.toString(), OrderData.class);

		if (orderData.locationId == null || orderData.orderItems == null || orderData.orderItems.isEmpty()) {
			return new List<OrderItemData>();
		}

		return process(orderData);
	}
}