public class DirectDebitEmailRemittanceBatch implements Database.Batchable<sObject>, Database.Stateful {

	private String today = System.now().format('dd-MM-yyyy');
	private Map<Id, String> accountsMissingFinanceContact = new Map<Id, String>();
    
    private static final String ACCOUNTS_EMAIL = 'accounts@thefirstmile.co.uk';
	private static final Id ORG_WIDE_EMAIL_ID = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :ACCOUNTS_EMAIL].Id;
	private static final String BASE_URL = URL.getOrgDomainURL().toExternalForm();
    private static final String LOGO_URL_FORMAT = BASE_URL + '/servlet/servlet.ImageServer?id={0}&oid=' + UserInfo.getOrganizationId();
	private static final String LOGO_URL = String.format(LOGO_URL_FORMAT, new Object[]{[SELECT Id FROM Document WHERE DeveloperName = 'FirstMileLogo' LIMIT 1].Id});

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator('SELECT Account__c, Account__r.Name, Account__r.CP_Account_Code__c, (SELECT AllocatedAmount__c, InvoiceId__r.InvoiceNo__c FROM PaymentAllocations__r) FROM Bank_Statement__c WHERE IsDirectDebit__c = TRUE AND Sent_DD_Remittance_Email__c = FALSE AND CreatedDate = TODAY ORDER BY Account__c');
	}

	public void execute(Database.BatchableContext BC, List<Bank_Statement__c> scope) {
		Set<Id> accountIds = new Set<Id>();
		for (Bank_Statement__c bankStatement : scope) {
			accountIds.add(bankStatement.Account__c);
			accountsMissingFinanceContact.put(bankStatement.Account__c, bankStatement.Account__r.Name);
		}

		List<AccountContactRelation> financeAcrs = [SELECT AccountId, Contact.Email, Portal_Link__c FROM AccountContactRelation
													WHERE AccountId IN :accountIds AND Roles INCLUDES ('Finance Contact') AND Contact.Email != null ORDER BY AccountId];

		Map<Id, List<AccountContactRelation>> financeContactsByAccount = new Map<Id, List<AccountContactRelation>>();
		for (AccountContactRelation financeAcr : financeAcrs) {
			if (financeContactsByAccount.containsKey(financeAcr.AccountId)) {
				financeContactsByAccount.get(financeAcr.AccountId).add(financeAcr);
			} else {
				financeContactsByAccount.put(financeAcr.AccountId, new List<AccountContactRelation>{financeAcr});
			}

			accountsMissingFinanceContact.remove(financeAcr.AccountId);
		}

		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		List<Bank_Statement__c> bankStatementToUpdate = new List<Bank_Statement__c>();

		for (Bank_Statement__c bankStatement : scope) {
			if (!financeContactsByAccount.containsKey(bankStatement.Account__c)) {
				continue;
			}

			Decimal totalAmount = 0;
			List<String> invoiceDetails = new List<String>();
			for (PaymentAllocation__c paymentAllocation : bankStatement.PaymentAllocations__r) {
				totalAmount += paymentAllocation.AllocatedAmount__c.setscale(2);
				invoiceDetails.add(paymentAllocation.InvoiceId__r.InvoiceNo__c + ' - £' + paymentAllocation.AllocatedAmount__c.setscale(2));
			}
			if (totalAmount <= 0) {
				continue;
			}

			String invoiceList = String.join(invoiceDetails, '<br>');

			for (AccountContactRelation financeAcr : financeContactsByAccount.get(bankStatement.Account__c)) {
				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				email.setUseSignature(false);
				email.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ID);
				email.setToAddresses(new String[] {financeAcr.Contact.Email});
				email.setSubject('Direct Debit Remittance for your account '+ bankStatement.Account__r.CP_Account_Code__c);
				email.saveAsActivity = false;
				email.setHtmlBody('Remittance Date: <b>' + today + '</b><br><br>' +
                                'Account Name: <b>' + bankStatement.Account__r.Name + '</b><br><br>' +
                                'First Mile Account Code: <b>' + bankStatement.Account__r.CP_Account_Code__c + '</b><br><br>' +
								'Total of invoices due for payment: <b>£' + totalAmount + '</b><br><br>' +
								'This amount will be debited from your account in the next 3 working days.<br><br>' +
                                'For a full list of invoices on your account including payment due dates, please visit <a href=\'' + financeAcr.Portal_Link__c + '\'>portal.thefirstmile.co.uk</a><br><br>' +
								'Your total debited is the total of all unpaid invoices which were due for payment up to and including today.<br><br>' +
                                'List of invoices being paid:<br><b>' + invoiceList + '</b><br><br><br><br>' +
								'<img src=' + LOGO_URL + ' alt="First Mile Logo"/>');
				emails.add(email);
			}

			bankStatement.Sent_DD_Remittance_Email__c = true;
			bankStatementToUpdate.add(bankStatement);
		}

		Messaging.sendEmail(emails);
		UPDATE bankStatementToUpdate;
	}


	public void finish(Database.BatchableContext BC) {
		if (accountsMissingFinanceContact.isEmpty()) {
			return;
		}

		String emailBody = '';
		for (Id accountId : accountsMissingFinanceContact.keySet()) {
			emailBody += '<a href=\'' + BASE_URL + '/' + accountId + '\'>' + accountsMissingFinanceContact.get(accountId) + '</a><br>';
		}

		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setUseSignature(false);
		email.setToAddresses(new String[] {ACCOUNTS_EMAIL});
		email.setSubject('Direct Debit Remittance failure, due to missing Finance Contact');
		email.setHtmlBody('Accounts missing Finance Contact: <br>' + emailBody);

		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
	}
}