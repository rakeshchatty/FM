public with sharing class InvoiceExtension {

	public Map<Account, List<Invoice_Line__c>> groupByLocation1 { get; private set; }
	public Map<Account, List<Invoice_Line__c>> groupByLocation2 { get; private set; }
	public Map<Account, Decimal> subtotals { get; private set; }

	private static final Integer MAX_LINES = 8000;

	public InvoiceExtension(ApexPages.StandardController ctrl) {
		List<Invoice_Line__c> lines = [SELECT Id, Location_Id__c, Location_Id__r.Name, Location_Id__r.PO_Number__c, Invoice_HeaderId__c, Order__r.Delivery_Date__c, Order__r.OrderNumber , Description__c, Name, Qty__c, UnitPrice__c, Amount__c, Order__r.PO_Number__c
									   FROM Invoice_Line__c
									   WHERE Invoice_HeaderId__c = :ctrl.getId()
									   ORDER BY Location_Id__c, Order__r.Delivery_Date__c];

		groupByLocation1 = new Map<Account, List<Invoice_Line__c>>();
		groupByLocation2 = new Map<Account, List<Invoice_Line__c>>();
		subtotals = new Map<Account, Decimal>();

		Map<Account, List<Invoice_Line__c>> groupByLocation = groupByLocation1;
		Id previousLocationId;
		Decimal subtotal = 0;
		Integer counter = 0;

		for (Invoice_Line__c invoiceLine : lines) {
			if (previousLocationId != invoiceLine.Location_Id__c) {
				subtotal = 0;
				if (counter > MAX_LINES) {
					groupByLocation = groupByLocation2;
				}
				groupByLocation.put(invoiceLine.Location_Id__r, new List<Invoice_Line__c>());
			}
			groupByLocation.get(invoiceLine.Location_Id__r).add(invoiceLine);

			previousLocationId = invoiceLine.Location_Id__c;
			subtotal += invoiceLine.Amount__c;
			counter++;
			subtotals.put(invoiceLine.Location_Id__r, subtotal);
		}
	}
}