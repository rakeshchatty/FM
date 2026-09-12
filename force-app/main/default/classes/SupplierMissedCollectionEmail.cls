public without sharing class SupplierMissedCollectionEmail {

	private static final Id ORG_WIDE_EMAIL_ID = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'supplychain@thefirstmile.co.uk'].Id;

 	@InvocableMethod(label='Send Supplier Missed Collection Emails')
	public static void send(List<Id> caseIds) {
		if (caseIds.isEmpty()) return;

		Map<Id, Map<Id, List<Missed_Collection__c>>> caseToMissedCollections = groupMissedCollectionsBySupplier(caseIds);
		if (caseToMissedCollections.isEmpty()) {
			return;
		}

		EmailTemplate template = [SELECT Id, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'SupplierMissedCollection' LIMIT 1];

		// Send an email to each supplier
		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
		for (Map<Id, List<Missed_Collection__c>> supplierToMissedCollections : caseToMissedCollections.values()) {
			for (Id supplierId : supplierToMissedCollections.keySet()) {
				List<Missed_Collection__c> missedCollections = supplierToMissedCollections.get(supplierId);
				Missed_Collection__c firstMissedCollection = missedCollections[0];
				Suppliers__c supplier = firstMissedCollection.Collection_Schedule__r.Supplier__r;

				String street = firstMissedCollection.Case__r.Location__r.BillingStreetLineSingle__c;
				String postcode = firstMissedCollection.Case__r.Location__r.BillingPostalCode;
				String body = generateBody(missedCollections);
				String htmlBody = template.HtmlValue.replace('{{0}}', body)
									.replace('{{1}}', supplier.Name)
									.replace('{{2}}', firstMissedCollection.Case__r.Location__r.Name)
									.replace('{{3}}', String.isNotBlank(street) ? street : '')
									.replace('{{4}}', String.isNotBlank(postcode) ? postcode : '');

				Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
				email.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ID);
				email.setToAddresses(new List<String>{supplier.Email__c});
				email.setSubject(template.Subject);
				email.setHtmlBody(htmlBody);
				email.setWhatId(firstMissedCollection.Case__c);
				emails.add(email);
			}
		}

		if (!emails.isEmpty()) {
			Messaging.sendEmail(emails);
		}
	}

	private static Map<Id, Map<Id, List<Missed_Collection__c>>> groupMissedCollectionsBySupplier(List<Id> caseIds) {
		List<Missed_Collection__c> missedCollections = [SELECT Case__c, SupplierId__c, Date__c, ProductName__c,
			Case__r.Location__r.Name, Case__r.Location__r.BillingStreetLineSingle__c, Case__r.Location__r.BillingPostalCode,
			Collection_Schedule__r.Supplier__r.Name, Collection_Schedule__r.Supplier__r.Email__c
			FROM Missed_Collection__c WHERE Case__c IN :caseIds AND IsExternalSupplier__c = true AND Collection_Schedule__r.Supplier__r.Email__c != null];

		Map<Id, Map<Id, List<Missed_Collection__c>>> caseToMissedCollections = new Map<Id, Map<Id, List<Missed_Collection__c>>>();
		Map<Id, List<Missed_Collection__c>> supplierToMissedCollections;
		for (Missed_Collection__c missedCollection : missedCollections) {
			if (!caseToMissedCollections.containsKey(missedCollection.Case__c)) {
				caseToMissedCollections.put(missedCollection.Case__c, new Map<Id, List<Missed_Collection__c>>());
			}
			supplierToMissedCollections = caseToMissedCollections.get(missedCollection.Case__c);

			if (!supplierToMissedCollections.containsKey(missedCollection.SupplierId__c)) {
				supplierToMissedCollections.put(missedCollection.SupplierId__c, new List<Missed_Collection__c>());
			}
			supplierToMissedCollections.get(missedCollection.SupplierId__c).add(missedCollection);
		}

		return caseToMissedCollections;
	}

	private static String generateBody(List<Missed_Collection__c> missedCollections) {
		String body = '';
		String template = '<tr><td align="center"><table width="90%" border="0" cellpadding="0" cellspacing="0">'
			+ '<tr><td width="70%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{0}</td>'
			+ '<td width="30%" style="text-align: center; font-size: 12px; padding: 10px 0px; line-height: 14px">{1}</td></tr>'
			+ '</table></td></tr>'
			+ '<tr><td align="center"><table width="90%" border="0" cellpadding="0" cellspacing="0">'
			+ '<tr><td height="1.5" bgcolor="#21D1D2" width="1"></td></tr></table></td></tr>';

		for (Missed_Collection__c missedCollection : missedCollections) {
			body += String.format(template, new List<String>{missedCollection.ProductName__c, missedCollection.Date__c.format()});
		}
		return body;
	}
}