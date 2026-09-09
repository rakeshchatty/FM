trigger InvoiceHeaderTrigger on Invoice_Header__c(after insert, before update, after update, before delete) {

	if (Trigger.isInsert) {
		Invoicing.createLines(Trigger.new);

		List < Invoice_Header__c > listCreditNotes = new List < Invoice_Header__c > ();
		for (Invoice_Header__c invoice : Trigger.new) {
			/* Bruno - 04.02.2019 -> 978 - Check for isCreditNote field, to create the correspondent Bank Statement and Payment Allocation */
			if (Invoicing.isCredit(invoice)) {
				listCreditNotes.add(invoice);
			}
		}
		if (!listCreditNotes.isEmpty()) {
			InvoiceHeaderTriggerHelper.processCreditNotes(listCreditNotes);
		}
	}

	if (Trigger.isUpdate && Trigger.isBefore) {
		List < Invoice_Header__c > listToUpdateAmounts = new List < Invoice_Header__c > ();
		//1251 if new Invoice updated from Daft to confirmed, but needs to be invoice method montly!, update AmountOutstanding__c = AmountInclVAT_f__c - AllocAmount__c. by Jessica
		/* Bruno 08.01.2019 - Changed the logic into the helper */
		for (Invoice_Header__c invoice : Trigger.new) {
			if (invoice.Salesforce__c && invoice.Status__c == Invoicing.STATUS_CLOSED && Trigger.oldMap.get(invoice.Id).Status__c != Invoicing.STATUS_CLOSED) {
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
		List<Invoice_Header__c> listToSage = new List<Invoice_Header__c>();
		List<Invoice_Header__c> listToPay = new List<Invoice_Header__c>();
		List<Invoice_Header__c> listToEmail = new List<Invoice_Header__c>();

		for (Invoice_Header__c invoice : Trigger.new) {
			Boolean isChangedToClosed = invoice.Status__c == Invoicing.STATUS_CLOSED && Trigger.oldMap.get(invoice.Id).Status__c != Invoicing.STATUS_CLOSED;
			Boolean isChangedToPay = invoice.Generate_Payment__c && !Trigger.oldMap.get(invoice.Id).Generate_Payment__c;

			if (isChangedToClosed) {
				listToEmail.add(invoice);

				if (invoice.InvoiceFrequency__c == Invoicing.FREQUENCY_IMMEDIATE) {
					listToSage.add(invoice);
				}
			}

			/* Bruno - 14-01-2019 - 1215 - Create Payments for Invoices paid by Card on CP */
			if (invoice.Salesforce__c && isChangedToPay) {
				listToPay.add(invoice);
			}
		}

		if (!listToSage.isEmpty()) {
			InvoiceHeaderTriggerHelper.createSageExtract(listToSage);
		}
		if (!listToPay.isEmpty()) {
			InvoiceHeaderTriggerHelper.payInvoices(listToPay);
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