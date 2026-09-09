public without sharing class Sage {

	public static List<SageExtract__c> createLines(Invoice_Line__c invoiceLine) {
		List <SageExtract__c> sageLines = new List <SageExtract__c>();
		sageLines.add(createSalesRecordInProductAccount(invoiceLine));
		sageLines.add(createSalesRecordInControlAccount(invoiceLine));
		sageLines.add(createVatRecordInVatAccount(invoiceLine));
		sageLines.add(createVatRecordInControlAccount(invoiceLine));
		invoiceLine.SageExtractCreated__c = true;
		return sageLines;
	}

	private static SageExtract__c createSalesRecordInProductAccount(Invoice_Line__c invoiceLine) {
		SageExtract__c sageLine = createLine(invoiceLine);
		sageLine.Name = 'Sales Record with Product Account';
		sageLine.AccountNumber__c = invoiceLine.Product__r.Nl_accode__c != null ? invoiceLine.Product_AccCode__c : '4000';
		sageLine.GoodsAmount__c = 0 - invoiceLine.Amount__c;
		return sageLine;
	}

	private static SageExtract__c createSalesRecordInControlAccount(Invoice_Line__c invoiceLine) {
		SageExtract__c sageLine = createLine(invoiceLine);
		sageLine.Name = 'Sales Record with Control Account';
		sageLine.AccountNumber__c = '1100';
		sageLine.GoodsAmount__c = invoiceLine.Amount__c;
		return sageLine;
	}

	private static SageExtract__c createVatRecordInVatAccount(Invoice_Line__c invoiceLine) {
		SageExtract__c sageLine = createLine(invoiceLine);
		sageLine.Name = 'Vat Record in Vat Account';
		sageLine.AccountNumber__c = '2200';
		sageLine.GoodsAmount__c = 0 - invoiceLine.VAT__c;
		return sageLine;
	}

	private static SageExtract__c createVatRecordInControlAccount(Invoice_Line__c invoiceLine) {
		SageExtract__c sageLine = createLine(invoiceLine);
		sageLine.Name = 'Vat Record in Control Account';
		sageLine.AccountNumber__c = '1100';
		sageLine.GoodsAmount__c = invoiceLine.VAT__c;
		return sageLine;
	}

	private static SageExtract__c createLine(Invoice_Line__c invoiceLine) {
		SageExtract__c sageLine = new SageExtract__c();
		sageLine.TransactionDate__c = invoiceLine.Invoice_HeaderId__r.DueDate__c;
		sageLine.Invoice_Line__c = invoiceLine.Id;
		return sageLine;
	}
}