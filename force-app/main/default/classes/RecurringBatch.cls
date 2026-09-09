/**
(c) 2018 Xpand-IT
Developed by Xpand-IT
@date Date of creation 01.2019
@author Bruno Mendes https://apps.xpand-it.com/jira/browse/FIRSTMILEPENTAHOINTSERV-1262

@description Jira 1262

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields
*/
global class RecurringBatch implements Database.Batchable<sObject> {

	String query;

	global RecurringBatch(String criteria) {
		query = 'SELECT Id, Last_Working_Day__c, Product__r.Name, Next_Date__c, First_Date__c, Account__c, Account__r.Enqix_Dead_Live__c,Type__c, Recur_every__c, Rec__c, PO_Number__c, Active__c, PO_from_Supplier__c, Supplier__c FROM Recurrings__c WHERE ' + criteria;
	}

	global RecurringBatch() {
		query = 'SELECT Id, Last_Working_Day__c, Product__r.Name, Next_Date__c, First_Date__c, Account__c, Account__r.Enqix_Dead_Live__c, Type__c, Recur_every__c, Rec__c, PO_Number__c, Active__c, PO_from_Supplier__c, Supplier__c FROM Recurrings__c WHERE Next_Date__c = TODAY and Active__c = TRUE';
	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) {
		List<Order> newOrders = new List<Order>();
		List<Recurrings__c> recurrings = new List<Recurrings__c>();

		Date today = system.today();
		for(sObject s : scope) {
			Recurrings__c r = (Recurrings__c)s;
			//Joao [JIRA 1630] - added de condition to verify if the account is not live and if it is not, deactivate de recurring and continue without creating the order.
			if (r.Account__r.Enqix_Dead_Live__c != 'live') {
				if(r.Active__c == true) {
					r.Active__c = false;
					recurrings.add(r);
					continue;
				}
			}

			Order newOrder = new Order(AccountId = r.Account__c,
				EffectiveDate = r.First_Date__c,
				Order_Placed_Date__c = today,
				Type = r.Type__c,
				PO_Number__c = r.PO_Number__c,
				IsSalesforceRecurring__c = true,
				PO_from_Supplier__c = r.PO_from_Supplier__c,
				Supplier__c = r.Supplier__c,
				RecurringId__c = r.Id,
				Recurring__c = true,
				Status = 'Confirmed',
				ConfirmationEmailStatus__c = 'Do Not Send');

			if (r.Type__c == 'Invoicing'){
				newOrder.Delivery_Status__c = 'Invoicing';
				newOrder.Type = 'Invoicing';
			} else {
				newOrder.Delivery_Status__c = 'Delivery';
				newOrder.Type = 'Regular';
			}

			switch on (r.Rec__c) {
				when 'Day' {
					r.Next_Date__c = r.Next_Date__c.addDays(Integer.valueof(r.Recur_every__c));
				}
				when 'Week' {
					r.Next_Date__c = r.Next_Date__c.addDays(Integer.valueof(r.Recur_every__c)*7);
				}
				when 'Month' {
					r.Next_Date__c = r.Next_Date__c.addMonths(Integer.valueof(r.Recur_every__c));
				}
			}
			newOrders.add(newOrder);
			recurrings.add(r);
		}

		Database.SaveResult[] orderToInsert = Database.insert(newOrders, false);
		LogRegister.createLogsUpsert(orderToInsert, newOrders, 'Recurring Batch - Order Insert', 'Insert', 'Order', 'AccountId');
		Database.SaveResult[] recurringsToUpdate = Database.update(recurrings, false);
		LogRegister.createLogsUpsert(recurringsToUpdate, recurrings, 'Recurring Batch - Recurrings Update', 'Update', 'Recurrings__c', 'Account__c');
	}

	global void finish(Database.BatchableContext BC) {}
}