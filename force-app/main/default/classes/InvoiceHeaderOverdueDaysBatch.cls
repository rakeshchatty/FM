public class InvoiceHeaderOverdueDaysBatch implements Database.Batchable<sObject> {
	@InvocableMethod(label='Update Overdue Days')
	public static void updateOverdueDays() {
		Database.executeBatch(new InvoiceHeaderOverdueDaysBatch(), 1000);
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Id, DaysOutstanding__c FROM Invoice_Header__c WHERE IsOverdueDaysSynced__c = false';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Invoice_Header__c> scope) {
		for (Invoice_Header__c invoiceHeader : scope) {
			invoiceHeader.OverdueDays__c = invoiceHeader.DaysOutstanding__c;
		}
		Database.update(scope, false);
	}

	public void finish(Database.BatchableContext BC) {
	}
}