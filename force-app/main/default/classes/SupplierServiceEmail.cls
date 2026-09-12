public without sharing class SupplierServiceEmail {

	private static final Id ORG_WIDE_EMAIL_ID = [SELECT Id FROM OrgWideEmailAddress WHERE Address = 'supplychain@thefirstmile.co.uk'].Id;

	@InvocableMethod(label='Send Supplier Service Emails')
	public static void send(List<Input> inputs) {

		EmailTemplate template = [SELECT Id, HtmlValue, Subject FROM EmailTemplate WHERE DeveloperName = 'SupplierService' LIMIT 1];

		List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

		for(Input input : inputs) {
			String title;
			String templateSubString1;
			String templateSubString2;
			String suspensionDetails;

			Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
			if (input.action == 'Add') {
				email.setSubject('First Mile: New Service Added - Please Review');
				title = 'NEW SERVICE ADDED';
				templateSubString1 = 'added a new service to your schedule';
				templateSubString2 = 'updated on your system against this collection schedule';
			} else if (input.action == 'Amend') {
				email.setSubject('First Mile: Service Amended - Please Review');
				title = 'NEW SERVICE AMENDMENT';
				templateSubString1 = 'amended one of your current collection schedules';
				templateSubString2 = 'updated on your system against this collection schedule';
			} else if (input.action == 'Delete') {
				email.setSubject('First Mile: Service Cancellation - Please Review');
				title = 'SERVICE CANCELLATION';
				templateSubString1 = 'cancelled one of your current collection schedules';
				templateSubString2 = 'removed from your system';
			} else if (input.action == 'Suspend') {
				email.setSubject('First Mile: Service Suspension - Please Review');
				title = 'SERVICE SUSPENSION';
				templateSubString1 = 'suspended one or more of your current collection schedules';
				templateSubString2 = 'removed from your system';
			} else {
				return;
			}

			List<Schedule__c> schedules = [SELECT TextDays__c, Supplier_Product_Name__c, Time__c, Po_Number_Supplier__c, Collection_Quantity__c, Supplier__r.Name, CollectionAggregator__c,
			Supplier__r.Email__c, Location__r.Name, Location__r.BillingStreetLineSingle__c, Location__r.BillingPostalCode, Start_Date__c, End_Date__c, WeekFrequency__c, NextCollectionDate__c FROM Schedule__c
			WHERE Location__c = :input.LocationId AND Po_Number_Supplier__c = :input.PoNumber AND (End_Date__c >= TODAY OR End_Date__c = Null) ORDER BY CollectionAggregator__c, DayIndex__c];

			Map<Id, String> aggregatorIdsMap = new Map<Id, String>();
			Integer aggCount = 1;
			for (Schedule__c schedule : schedules) {
				if (!aggregatorIdsMap.containsKey(schedule.CollectionAggregator__c)) {
					aggregatorIdsMap.put(schedule.CollectionAggregator__c, 'Schedule ' + aggCount);
					aggCount++;
				}
			}

			List<ScheduleSuspension__c> scheduleSuspensions = [SELECT Aggregator__c, IsActive__c, IsEveryYear__c, SuspensionDate__c, ReactivationDate__c FROM ScheduleSuspension__c
			WHERE Aggregator__c = :aggregatorIdsMap.keySet() AND ReactivationDate__c > TODAY ORDER BY Aggregator__c, ReactivationDate__c DESC];

			String body = generateBody(schedules, aggregatorIdsMap);
			String suspensionBody = generateSuspensionBody(scheduleSuspensions, aggregatorIdsMap);

			String address = schedules[0].Location__r.BillingStreetLineSingle__c + ', ' + schedules[0].Location__r.BillingPostalCode;
			String htmlBody = template.HtmlValue.replace('{{0}}', body)
									.replace('{{1}}', title)
									.replace('{{2}}', schedules[0].Supplier__r.Name)
									.replace('{{3}}', templateSubString1)
									.replace('{{4}}', 'Customer Name: ' + schedules[0].Location__r.Name + '<br>' + 'Customer Address: ' + address + '<br>' + 'Stream: ' + schedules[0].Supplier_Product_Name__c + '<br>' + 'PO Number: ' + schedules[0].Po_Number_Supplier__c)
									.replace('{{5}}', templateSubString2)
									.replace('{{6}}', suspensionBody);
			email.setOrgWideEmailAddressId(ORG_WIDE_EMAIL_ID);
			email.setToAddresses(new List<String>{schedules[0].Supplier__r.Email__c});
			email.setHtmlBody(htmlBody);
			email.setWhatId(input.caseId);
			emails.add(email);
		}

		if (!emails.isEmpty()) {
			Messaging.sendEmail(emails);
		}
	}

	private static String generateBody(List<Schedule__c> schedules, Map<Id, String> aggregatorIdsMap) {
		String body = '';
		String template = '<tr><td align="center"><table width="95%" border="0" cellpadding="0" cellspacing="0">'
			+ '<tr><td width="12%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{0}</td>'
			+ '<td width="14%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{1}</td>'
			+ '<td width="10%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{2}</td>'
			+ '<td width="7%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{3}</td>'
			+ '<td width="14%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{4}</td>'
			+ '<td width="14%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{5}</td>'
			+ '<td width="15%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{6}</td>'
			+ '<td width="14%" style="text-align: center; font-size: 12px; padding: 10px 0px; line-height: 14px">{7}</td></tr>'
			+ '</table></td></tr>'
			+ '<tr><td align="center"><table width="95%" border="0" cellpadding="0" cellspacing="0">'
			+ '<tr><td height="1.5" bgcolor="#21D1D2" width="1"></td></tr></table></td></tr>';

		for (Schedule__c schedule : schedules) {
			body += String.format(template, new List<String>{aggregatorIdsMap.get(schedule.CollectionAggregator__c), schedule.TextDays__c,
				schedule.Time__c, String.valueOf(schedule.Collection_Quantity__c),
				(String.valueOf(schedule.Start_Date__c) != null) ? String.valueOf(schedule.Start_Date__c) : '-',
				(String.valueOf(schedule.End_Date__c) != null) ? String.valueOf(schedule.End_Date__c) : '-',
				(Integer.valueOf(schedule.WeekFrequency__c) > 1) ? String.valueOf('Once ' + schedule.WeekFrequency__c + ' weeks') : 'Every week',
				(String.valueOf(schedule.NextCollectionDate__c) != null) ? String.valueOf(schedule.NextCollectionDate__c) : '-'});
		}
		return body;
	}

	private static String generateSuspensionBody(List<ScheduleSuspension__c> scheduleSuspensions, Map<Id, String> aggregatorIdsMap) {
		if (scheduleSuspensions.isEmpty()) {
			return '';
		}

		String body = '';
		String template = '<tr><td align="center"><table width="95%" border="0" cellpadding="0" cellspacing="0">'
			+ '<tr><td width="20%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{0}</td>'
			+ '<td width="25%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{1}</td>'
			+ '<td width="25%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{2}</td>'
			+ '<td width="15%" style="font-size: 12px; padding: 10px 0px; line-height: 14px">{3}</td>'
			+ '<td width="15%" style="text-align: center; font-size: 12px; padding: 10px 0px; line-height: 14px">{4}</td></tr>'
			+ '</table></td></tr>'
			+ '<tr><td align="center"><table width="95%" border="0" cellpadding="0" cellspacing="0">'
			+ '<tr><td height="1.5" bgcolor="#21D1D2" width="1"></td></tr></table></td></tr>';

		for (ScheduleSuspension__c scheduleSuspension : scheduleSuspensions) {
			body += String.format(template, new List<String>{aggregatorIdsMap.get(scheduleSuspension.Aggregator__c),
				String.valueOf(scheduleSuspension.SuspensionDate__c), String.valueOf(scheduleSuspension.ReactivationDate__c),
				String.valueOf(scheduleSuspension.IsActive__c), String.valueOf(scheduleSuspension.IsEveryYear__c)});
		}
		return body;
	}

	public class Input {
		@InvocableVariable(required=true)
		public String LocationId;
		@InvocableVariable(required=true)
		public String Action;
		@InvocableVariable(required=true)
		public Id CaseId;
		@InvocableVariable(required=true)
		public String PoNumber;
	}
}