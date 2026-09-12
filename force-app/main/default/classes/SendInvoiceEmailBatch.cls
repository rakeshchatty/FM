public class SendInvoiceEmailBatch implements Database.Batchable<sObject>, Schedulable {

	private static final String[] STATUS_TO_PROCESS = new String[]{'New', 'Retry'};
	private static final SendGridSetting__c SEND_GRID = SendGridSetting__c.getOrgDefaults();

	@InvocableMethod(label='Send Invoice Email Batch')
	public static void sendEmails() {
		Database.executeBatch(new SendInvoiceEmailBatch(), 25);
	}

	public void execute(SchedulableContext sc) {
		sendEmails();
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		if (!SEND_GRID.IsInvoiceEmailEnabled__c) {
			// DUMMY, no rows returned
			String query = 'SELECT Id FROM SendInvoiceEmail__c WHERE CreatedDate = NEXT_YEAR';
			return Database.getQueryLocator(query);
		}

		String query = 'SELECT Invoice__c, Invoice__r.LineCount__c, Invoice__r.Account__r.FinanceContact__c FROM SendInvoiceEmail__c WHERE Status__c IN :STATUS_TO_PROCESS ORDER BY Invoice__r.LineCount__c';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<SendInvoiceEmail__c> invoiceEmails) {
		List<Id> invoiceIds = new List<Id>();
		for (SendInvoiceEmail__c invoiceEmail : invoiceEmails) {
			if (invoiceEmail.Invoice__r.LineCount__c == 0) {
				invoiceEmail.Status__c = 'Error - No Lines';
			} else if (invoiceEmail.Invoice__r.LineCount__c > SEND_GRID.MaxInvoiceLinesForPDFGeneration__c) {
				invoiceEmail.Status__c = 'Error - More Lines';
			} else if (invoiceEmail.Invoice__r.Account__r.FinanceContact__c == null) {
				invoiceEmail.Status__c = 'Error - Finance Contact';
			} else {
				invoiceEmail.Status__c = 'Sent';
				invoiceIds.add(invoiceEmail.Invoice__c);
			}
			invoiceEmail.Account__c = invoiceEmail.Invoice__r.Account__c;
		}

		SendInvoiceEmail.send(invoiceIds);
		UPDATE invoiceEmails;
	}

	private static Map<Id, List<Id>> groupByAccount(List<SendInvoiceEmail__c> invoiceEmails) {
		Map<Id, List<Id>> accountToInvoice = new Map<Id, List<Id>>();
		for (SendInvoiceEmail__c invoiceEmail : invoiceEmails) {
			if (accountToInvoice.containsKey(invoiceEmail.Invoice__r.Account__c)) {
				accountToInvoice.get(invoiceEmail.Invoice__r.Account__c).add(invoiceEmail.Invoice__c);
			} else {
				accountToInvoice.put(invoiceEmail.Invoice__r.Account__c, new List<Id>{invoiceEmail.Invoice__c});
			}
		}

		return accountToInvoice;
	}

	public void finish(Database.BatchableContext batchContext) {}
}