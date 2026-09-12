public class InvoiceHeaderTriggerHelper {

	public static void populateAmounts(List<Invoice_Header__c> headers) {
		Id fuelSurchargeProductId = FuelSurchargeSetting__c.getOrgDefaults().ProductId__c;

		Map<Id, Invoice_Header__c> headerMap = new Map<Id, Invoice_Header__c>([SELECT Id, OrderLookUp__r.PaymentReference__c, OrderLookUp__r.CreditCard_Payment__c,
				(SELECT Amount__c, VATRate__c, Order_Product__r.Product2Id FROM Invoice_Lines__r)
			FROM Invoice_Header__c WHERE Id IN :headers]);

		for (Invoice_Header__c header : headers) {
			Invoice_Header__c h = headerMap.get(header.Id);
			header.AmountExclVAT__c = header.FuelSurchargeExclVAT__c = 0;
			for (Invoice_Line__c line : h.Invoice_Lines__r) {
				header.AmountExclVAT__c += line.Amount__c;
				header.FuelSurchargeExclVAT__c += (line.Order_Product__r.Product2Id == fuelSurchargeProductId) ? line.Amount__c : 0;
			}

			header.VAT__c = Vat.calculate(h);
			header.AmountOutstanding__c = (header.AmountExclVAT__c + header.VAT__c - header.AllocAmount__c).setScale(2);
			header.Outstanding__c = header.AmountOutstanding__c > 0 ? header.Account__c : null;

			//Joao [JIRA 1612] - added to set generate payment and payment reference
			//Fix jira 1677/1673
			if (h.OrderLookUp__r.CreditCard_Payment__c) {
				header.Payment_Reference__c = h.OrderLookUp__r.PaymentReference__c;
			}
		}
	}
}