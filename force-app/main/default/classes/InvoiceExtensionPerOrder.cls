public with sharing class InvoiceExtensionPerOrder {

	string recordId {
        get;
        set;
    }
	public Invoice_Header__c invHeader {
        get;
        private set;
    }

	public List<Invoice_Line__c> lines{
		get;
		private set;
	}

	

	
	public InvoiceExtensionPerOrder(ApexPages.StandardController ctrl) {
		recordId = ctrl.getId();
		invHeader = [SELECT Id, Status__c, AmountOutstanding__c, Account__r.Enqix_Payment_Method__c, Payment_Due_Date__c, DueDate__c, AmountInclVAT_f__c FROM Invoice_Header__c WHERE Id =: recordId];
		

		

		lines = [SELECT Id, Location_Id__c, Location_Id__r.Name, Invoice_HeaderId__c, Order__r.Delivery_Date__c, Order__r.OrderNumber , Description__c, Name, Qty__c, UnitPrice__c, Amount__c
										FROM Invoice_Line__c 
										WHERE Invoice_HeaderId__c = :invHeader.Id];
	
    }
}