public class SendInvoiceEmail {

	private static final SendGridSetting__c SEND_GRID = SendGridSetting__c.getOrgDefaults();

	@InvocableMethod(label='Send Invoice Email via SendGrid')
	public static void send(Id[] invoiceIds) {
		if (!SEND_GRID.IsInvoiceEmailEnabled__c) {
			return;
		}

		List<Invoice_Header__c> invoices = [SELECT Original_Invoice_to_Credit__c, InvoiceFrequency__c, InvoiceNo__c, Account__c, Account__r.EffectiveAttribution__c, Account__r.CP_Account_Code__c,
			Account__r.OwningEntity__r.InvoiceTemplate__c, Account__r.OwningEntity__r.CreditNoteTemplate__c, Account__r.OwningEntity__r.InvoiceSenderName__c, Account__r.OwningEntity__r.InvoiceSenderEmail__c FROM Invoice_Header__c WHERE Id IN :invoiceIds];
		Map<Id, List<AccountContactRelation>> acrMap = getFinanceContact(invoices);

		new SendGridEmail(createSendGridInput(invoices, acrMap)).send();
	}

	private static List<SendGridEmail.Input> createSendGridInput(List<Invoice_Header__c> invoices, Map<Id, List<AccountContactRelation>> acrMap) {
		List<SendGridEmail.Input> inputs = new List<SendGridEmail.Input>();
		for (Invoice_Header__c invoice : invoices) {
			if (!acrMap.containsKey(invoice.Account__c)) {
				continue;
			}

			List<String> toName = new List<String>();
			List<String> toAddress = new List<String>();
			for (AccountContactRelation acr : acrMap.get(invoice.Account__c)) {
				toName.add(acr.Contact.Name);
				toAddress.add(acr.Contact.Email);
			}
			if (toAddress.isEmpty()) {
				continue;
			}

			SendGridEmail.Input input = new SendGridEmail.Input();
			input.templateId = Invoicing.isCredit(invoice) ? invoice.Account__r.OwningEntity__r.CreditNoteTemplate__c : invoice.Account__r.OwningEntity__r.InvoiceTemplate__c;
			input.fromEmail = invoice.Account__r.OwningEntity__r.InvoiceSenderEmail__c;
			input.fromName = invoice.Account__r.OwningEntity__r.InvoiceSenderName__c;
			input.toName = toName;
			input.toAddress = toAddress;
			input.attribution = invoice.Account__r.EffectiveAttribution__c;
			input.var01 = invoice.Account__r.CP_Account_Code__c;
			input.var02 = invoice.InvoiceNo__c;
			input.contentDocumentId = createPdf(invoice);
			inputs.add(input);
		}

		return inputs;
	}

	private static Map<Id, List<AccountContactRelation>> getFinanceContact(List<Invoice_Header__c> invoices) {
		Set<Id> accountIds = new Set<Id>();
		for (Invoice_Header__c invoice : invoices) {
			accountIds.add(invoice.Account__c);
		}

		List<AccountContactRelation> acrs = AcrUtil.getFinanceContactRelation(accountIds);
		Map<Id, List<AccountContactRelation>> acrMap = new Map<Id, List<AccountContactRelation>>();
		for (AccountContactRelation acr : acrs) {
			if (acrMap.containsKey(acr.AccountId)) {
				acrMap.get(acr.AccountId).add(acr);
			} else {
				acrMap.put(acr.AccountId, new List<AccountContactRelation>{acr});
			}
		}
		return acrMap;
	}

	private static String getFileName(Invoice_Header__c invoice) {
		return invoice.InvoiceNo__c;
	}

	private static Id getExistingPdf(Invoice_Header__c invoice) {
		return [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :invoice.Id AND ContentDocument.Title = :getFileName(invoice) LIMIT 1]?.ContentDocumentId;
	}

	private static Id createPdf(Invoice_Header__c invoice) {
		Id contentDocumentId = getExistingPdf(invoice);
		if (String.isNotBlank(contentDocumentId)) {
			return contentDocumentId;
		}

		PageReference pdf;
		if (invoice.InvoiceFrequency__c == Invoicing.FREQUENCY_IMMEDIATE) {
			pdf = Page.InvoiceDocumentPdf;
		} else {
			pdf = Page.InvoiceMonthPdf;
		}
		pdf.getParameters().put('Id', invoice.Id);
		Blob fileContent = Test.isRunningTest() ? Blob.valueOf('test') : pdf.getContentAsPdf();

		String filename = getFileName(invoice);
		ContentVersion contentVersion = new ContentVersion(Title = filename, VersionData = fileContent, PathOnClient = filename + '.PDF');
		INSERT contentVersion;
		contentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id].ContentDocumentId;
		ContentDocumentLink contentDocumentLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = invoice.Id, ShareType = 'I');
		INSERT contentDocumentLink;

		return contentDocumentId;
	}
}