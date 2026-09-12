public without sharing class GoogleAdsEventExporter {

	private static final String FILE_HEADER = 'event_name,email_1_hashed,phone_1_hashed_format_a,first_name_hashed,last_name_hashed,street_address_hashed,country,state,city,zipcode,event_time,transaction_id,currency,value,gclid,cv:services_wanted,cv:est_annual_revenue';
	private static final GoogleAdsSetting__c settings = GoogleAdsSetting__c.getOrgDefaults();
	private static final Id ORG_WIDE_EMAIL_ID = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'noreply@thefirstmile.co.uk'].Id;

	private List<GoogleAdsEvent__c> eventsToProcess = new List<GoogleAdsEvent__c>();

	public void export() {
		String csvContent = buildCsv();
		if (String.isBlank(csvContent)) {
			return;
		}

		Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
		attachment.setFileName('GoogleAdsEvents.csv');
		attachment.setContentType('text/csv');
		attachment.setBody(Blob.valueOf(csvContent));

		sendEmail(attachment);

		for(GoogleAdsEvent__c event : eventsToProcess) {
			event.Status__c = 'Processed';
		}

		if (!eventsToProcess.isEmpty()) {
			UPDATE eventsToProcess;
		}
	}

	private String buildCsv() {
		List<String> rows = new List<String>();
		rows.addAll(getLeadEventRows());
		rows.addAll(getOpportunityEventRows());
		rows.addAll(getOrderEventRows());
		if (rows.isEmpty()) {
			return null;
		}
		rows.add(0, FILE_HEADER);
		return String.join(rows, '\n');
	}

	private List<String> getLeadEventRows() {
		List<String> leadStatusToSkip = StringUtil.splitTrim(settings.LeadStatusToSkip__c, ',');

		List<Lead> leads = [SELECT Email, MobilePhone, FirstName, LastName, Street, CountryCode, StateCode, City, PostalCode, CreatedDate, GCLID__c, Services_wanted__c, Estimated_Value__c
			FROM Lead WHERE IsConverted = false AND (Email != null OR MobilePhone != null) AND Status NOT IN :leadStatusToSkip AND CreatedDate = THIS_MONTH
			ORDER BY LastModifiedDate DESC];

		List<String> rows = new List<String>();
		for (Lead lead : leads) {
			rows.add(formatCsv('qualified_leads', lead.Email, lead.MobilePhone, lead.FirstName, lead.LastName,
				lead.Street, lead.CountryCode, lead.StateCode, lead.City, lead.PostalCode,
				lead.CreatedDate, null, null, null, normalizeGclid(lead.GCLID__c),
				lead.Services_wanted__c, String.valueOf(lead.Estimated_Value__c)));
		}
		return rows;
	}

	private List<String> getOpportunityEventRows() {
		Map<Id, DateTime> events = getEvents('Opportunity');
		List<Opportunity> opportunities = [SELECT Account.FinanceContact__r.Email, Account.FinanceContact__r.MobilePhone, Account.FinanceContact__r.FirstName, Account.FinanceContact__r.LastName,
			Account.BillingStreet, Account.BillingCountryCode, Account.BillingStateCode, Account.BillingCity, Account.BillingPostalCode, Estimated_Annual_Sales__c, GCLID__c, Services__c, CurrencyIsoCode
			FROM Opportunity WHERE Id IN : events.keyset()];

		List<String> rows = new List<String>();
		for (Opportunity opp : opportunities) {
			rows.add(formatCsv('opportunities_won', opp.Account.FinanceContact__r?.Email, opp.Account.FinanceContact__r?.MobilePhone, opp.Account.FinanceContact__r?.FirstName, opp.Account.FinanceContact__r?.LastName,
				opp.Account?.BillingStreet, opp.Account?.BillingCountryCode, opp.Account?.BillingStateCode, opp.Account?.BillingCity, opp.Account?.BillingPostalCode,
				events.get(opp.Id), null, opp.CurrencyIsoCode.toLowerCase(), String.valueOf(opp.Estimated_Annual_Sales__c), normalizeGclid(opp.GCLID__c),
				opp.Services__c, String.valueOf(opp.Estimated_Annual_Sales__c)));
		}
		return rows;
	}

	private List<String> getOrderEventRows() {
		Map<Id, DateTime> events = getEvents('Order');
		List<Order> orders = [SELECT Contact__r.Email, Contact__r.MobilePhone, Contact__r.FirstName, Contact__r.LastName,
			Account.BillingStreet, Account.BillingCountryCode, Account.BillingStateCode, Account.BillingCity, Account.BillingPostalCode,
			Account.Opportunity__r.Services__c, Account.Opportunity__r.Estimated_Annual_Sales__c,
			CreatedDate, OrderNumber, TotalAmount, CurrencyIsoCode FROM Order WHERE Id IN : events.keySet()];

		List<String> rows = new List<String>();
		for (Order order : orders) {
			rows.add(formatCsv('new_account_order', order.Contact__r?.Email, order.Contact__r?.MobilePhone, order.Contact__r?.FirstName, order.Contact__r?.LastName,
				order.Account?.BillingStreet, order.Account?.BillingCountryCode, order.Account?.BillingStateCode, order.Account?.BillingCity, order.Account?.BillingPostalCode,
				order.CreatedDate, order.OrderNumber, order.CurrencyIsoCode.toLowerCase(), String.valueOf(order.TotalAmount), null,
				order.Account?.Opportunity__r?.Services__c, String.valueOf(order.Account?.Opportunity__r?.Estimated_Annual_Sales__c)));
		}
		return rows;
	}

	private Map<Id, DateTime> getEvents(String type) {
		Map<Id, DateTime> events = new Map<Id, DateTime>();
		for (GoogleAdsEvent__c event : [SELECT Id__c, CreatedDate FROM GoogleAdsEvent__c WHERE Type__c = :type AND Status__c = 'New']) {
			events.put(event.Id__c, event.CreatedDate);
			eventsToProcess.add(event);
		}
		return events;
	}

	private String formatCsv(String eventName, String email, String phone, String firstName, String lastName,
		String street, String countryCode, String stateCode, String city, String zip,
		DateTime eventTime, String transactionId, String isoCurrencyCode, String value, String gclid,
		String servicesWanted, String estimatedAnnualValue) {

		return String.join(new List<String>{eventName,
			sha256(lower(email)),
			sha256(normalizePhone(phone)),
			sha256(normalize(firstName, '[^a-z]', true)),
			sha256(normalize(lastName, '[^a-z]', true)),
			sha256(lower(street)),
			lower(countryCode),
			lower(stateCode),
			normalize(city, '[^a-z]', false),
			normalize(zip, '[^a-z0-9]', true),
			eventTime != null ? String.valueOf(eventTime.getTime() / 1000) : '',
			transactionId, isoCurrencyCode, value, gclid, lower(servicesWanted), estimatedAnnualValue}, ',');
	}

	private String sha256(String text) {
		return (!String.isBlank(text)) ? EncodingUtil.convertToHex(Crypto.generateDigest('sha-256', Blob.valueOf(text))) : '';
	}

	private void sendEmail(Messaging.EmailFileAttachment attachment) {
		Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
		email.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ID);
		email.setToAddresses(StringUtil.splitTrim(settings.ExternalInbox__c, ','));
		email.setSubject('Google Ads Event Export');
		email.setPlainTextBody('Attached Google Ads CSV file.');
		email.setFileAttachments(new Messaging.EmailFileAttachment[]{attachment});
		Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
	}

	private String normalizeGclid(String gclid) {
		return (String.isBlank(gclid) || gclid.toLowerCase() == 'gaconnector_gclid') ? '' : gclid;
	}

	private String normalizePhone(String phone) {
		if (String.isBlank(phone)) return '';
		String digitsOnly = phone.replaceAll('[^0-9]', '');
		if (digitsOnly.startsWith('0')) digitsOnly = digitsOnly.substring(1);
		return StringUtil.abbreviate(digitsOnly, 15);
	}

	private String normalize(String text, String retainRegEx, Boolean removeAllSpace) {
		if (String.isBlank(text)) return '';
		String result = lower(text).replaceAll(retainRegEx, '');
		return (!removeAllSpace) ? result : result.replaceAll('\\s+', ''); // remove internal spaces
	}

	private String lower(String text) {
		return StringUtil.lower(StringUtil.trim(text));
	}
}