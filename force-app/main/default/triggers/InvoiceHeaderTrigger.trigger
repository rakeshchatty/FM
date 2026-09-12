trigger InvoiceHeaderTrigger on Invoice_Header__c(after insert, before update, after update, before delete) {

	if (Trigger.isInsert) {
		Invoicing.createLines(Trigger.new);
	}

	if (Trigger.isUpdate && Trigger.isBefore) {
		List < Invoice_Header__c > listToUpdateAmounts = new List < Invoice_Header__c > ();
		for (Invoice_Header__c invoice : Trigger.new) {
			if (invoice.Salesforce__c && invoice.Status__c == Invoicing.STATUS_CLOSED && Trigger.oldMap.get(invoice.Id).Status__c != Invoicing.STATUS_CLOSED && invoice.BusinessCentralId__c == null) {
				listToUpdateAmounts.add(invoice);
			}
		}

		if (listToUpdateAmounts.size() > 0) {
			InvoiceHeaderTriggerHelper.populateAmounts(listToUpdateAmounts);
		}
	}

	/*
	836 JIRA - When the 'ToPublish__c' on the HEADER is updated to TRUE
	*   > the Status__c on the Header is updated to something != Draft, != Emailed
	*   > AmountExclVAT__c > 0 on the Header
	*   > Changes made: This section will run for both when inserting and updating. 02/11/2018
	*/
	if (Trigger.isUpdate && Trigger.isAfter) {
		List<Invoice_Header__c> listToEmail = new List<Invoice_Header__c>();

		for (Invoice_Header__c invoice : Trigger.new) {
			Boolean isChangedToClosed = invoice.Status__c == Invoicing.STATUS_CLOSED && Trigger.oldMap.get(invoice.Id).Status__c != Invoicing.STATUS_CLOSED;

			if (isChangedToClosed) {
				listToEmail.add(invoice);
			}
		}

		if (!listToEmail.isEmpty()) {
			List<SendInvoiceEmail__c> invoiceEmails = new List<SendInvoiceEmail__c>();
			for (Invoice_Header__c invoice : listToEmail) {
				invoiceEmails.add(new SendInvoiceEmail__c(Invoice__c = invoice.Id));
			}
			INSERT invoiceEmails;
		}
	}

	if (Trigger.isDelete) {
		DELETE [SELECT Id FROM Invoice_Line__c WHERE Invoice_HeaderId__c IN :Trigger.oldMap.keyset()];
	}
}