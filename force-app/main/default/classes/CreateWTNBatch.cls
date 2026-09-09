public without sharing class CreateWTNBatch implements Database.Batchable < sObject > {

	public Database.QueryLocator start(Database.BatchableContext BC) {
		String query = 'SELECT Name, Parent.Name, Parent.BillingStreetLineSingle__c, Parent.BillingCountry, Parent.BillingPostalCode, Parent.Business_Registration_Number__c, Broker_Cleaner__c, (SELECT Supplier__c, Supplier__r.Name, Supplier__r.Address__c, Supplier__r.Postcode__c, Supplier__r.Company_Registration_Number__c, Supplier_Product__r.Product__c, Supplier_Product__r.Product__r.Waste_Category__c, CreatedDate FROM Collections__r WHERE (End_Date__c = null OR End_Date__c > TODAY) AND Supplier_Product__r.Product__r.WTN_Product__c = \'Season Ticket\' ORDER BY Supplier__c, CreatedDate), (SELECT Id FROM seasonTicketWTNs__r WHERE Name LIKE \'Season%\' LIMIT 1) FROM Account WHERE Id IN (SELECT Location__c FROM Schedule__c WHERE Location__r.isLive__c = true AND (End_Date__c = null OR End_Date__c > TODAY) AND Supplier_Product__r.Product__r.WTN_Product__c = \'Season Ticket\')';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List <Account> accounts) {
		Map<String, SeasonTicketWTN__c> complianceDoumentMap = new Map<String, SeasonTicketWTN__c>();
		Map<String, SeasonTicketWTNProduct__c> wtnWasteCategoryMap = new Map<String, SeasonTicketWTNProduct__c>();

		for (Account account : accounts) {
			List<SeasonTicketWTN__c> complianceDouments = new List<SeasonTicketWTN__c>();

			if (!account.seasonTicketWTNs__r.isEmpty() || account.Collections__r.isEmpty()) {
				continue;
			}

			String parentAcountAddress = account.Parent.BillingStreetLineSingle__c + ', ' + account.Parent.BillingCountry;
			Date minimumStartDate;
			for (Schedule__c sch : account.Collections__r) {
				String cdKey = account + '-' + sch.Supplier__c;
				if (!complianceDoumentMap.containsKey(cdKey)) {
					Date startDate = getStartDate(sch.CreatedDate.date());
					if (minimumStartDate == null || minimumStartDate > startDate) {
						minimumStartDate = startDate;
					}

					List<String> dt = startDate.format().split('/');
					String name = 'Season Ticket WTN - ' + account.Name.left(47) + ' - ' + dt[0] + '-' + dt[1] + '-' + dt[2];
					SeasonTicketWTN__c complianceDocument = new SeasonTicketWTN__c(
						Name = name, // TODO: Rob: Name should include supplier info?
						Contractor__c = sch.Supplier__c,
						Account__c = account.Id,
						StartDate__c = startDate,
						Annual_Caption__c = true,
						WasteHierarchyDeclaration__c = true,
						MostRecent__c = true);
					if (account.Broker_Cleaner__c) {
						complianceDocument.SectionD2_Brkr_CompName__c = account.Parent.Name;
						complianceDocument.SectionD2_Brkr_Address__c = parentAcountAddress;
						complianceDocument.SectionD2_Bkr_PostCode__c = account.Parent.BillingPostalCode;
						complianceDocument.SectionD2_Brkr_RegNo__c = account.Parent.Business_Registration_Number__c;
					} else if (sch.Supplier__r.Name != 'First Mile Ltd') {
						complianceDocument.SectionD2_Brkr_CompName__c = 'First Mile Ltd';
						complianceDocument.SectionD2_Brkr_Address__c = '70 - 71 Wells St, Fitzrovia, London';
						complianceDocument.SectionD2_Bkr_PostCode__c = 'W1T 3QE';
						complianceDocument.SectionD2_Brkr_RegNo__c = null;
					}
					complianceDoumentMap.put(cdKey, complianceDocument);
					complianceDouments.add(complianceDocument);
				}

				String productKey = cdKey + '-' + sch.Supplier_Product__r.Product__c;
				if (!wtnWasteCategoryMap.containsKey(productKey)) {
					SeasonTicketWTNProduct__c wtnProduct = new SeasonTicketWTNProduct__c(
						WTN__r = complianceDoumentMap.get(cdKey),
						Product__c = sch.Supplier_Product__r.Product__c,
						Waste_Category__c = sch.Supplier_Product__r.Product__r.Waste_Category__c);
					wtnWasteCategoryMap.put(productKey, wtnProduct);
				}
			}

			Date endDate = minimumStartDate.addYears(1).addDays(-1);
			for (SeasonTicketWTN__c cd : complianceDouments) {
				cd.EndDate__c = endDate;
			}
		}

		if (!complianceDoumentMap.isEmpty()) {
			INSERT complianceDoumentMap.values();

			for (SeasonTicketWTNProduct__c wtnProduct : wtnWasteCategoryMap.values()) {
				wtnProduct.WTN__c = wtnProduct.WTN__r.Id;
			}
			INSERT wtnWasteCategoryMap.values();
		}
	}

	@TestVisible
	private static Date getStartDate(Date inputDate) {
		Integer inputMonth = inputDate.month();
		Integer inputDay = inputDate.day();
		Date currentDate = Date.today();
		Integer currentMonth = currentDate.month();
		Integer currentDay = currentDate.day();

		Integer baseYear = (inputMonth > currentMonth || (inputMonth == currentMonth && inputDay > currentDay)) ? currentDate.year() - 1 : currentDate.year();
		return Date.newInstance(baseYear, inputMonth, inputDay);
	}

	public void finish(Database.BatchableContext BC) {

	}
}