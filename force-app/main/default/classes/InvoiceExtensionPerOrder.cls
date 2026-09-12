public with sharing class InvoiceExtensionPerOrder {

	public LegalEntity__c entity { get; private set; }
	public Invoice_Header__c invHeader { get; private set; }
	public List<Invoice_Line__c> lines{ get; private set; }
	public String poNumber{ get; private set; }

	public InvoiceExtensionPerOrder(ApexPages.StandardController ctrl) {
		invHeader = [SELECT Status__c, AmountOutstanding__c, Account__r.Enqix_Payment_Method__c, Payment_Due_Date__c, DueDate__c, AmountInclVAT_f__c, Account__r.OwningEntity__c, Account__r.PO_Number__c, Account__r.AdHocPONumber__c
			FROM Invoice_Header__c WHERE Id = :ctrl.getId()];

		lines = [SELECT Location_Id__c, Location_Id__r.Name, Invoice_HeaderId__c, DeliveryDate__c, Order__r.OrderNumber, Description__c, Name, Qty__c, UnitPrice__c, Amount__c, 
			PO_Number__c, Order_Product__r.Order.Is_wheelie_bin_order__c, Order_Product__r.Order.Recurring__c
			FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :invHeader.Id];

		entity = LegalEntity.get(invHeader.Account__r.OwningEntity__c);

		if (lines[0].Order_Product__r.Order.Is_wheelie_bin_order__c || lines[0].Order_Product__r.Order.Recurring__c) {
			poNumber = invHeader.Account__r.PO_Number__c;
		} else {
			poNumber = invHeader.Account__r.AdHocPONumber__c;
		}
	}
}