/** 
(c) XPAND-IT
Developed by Xpand-IT (Braga), Portugal
@date  10.2018
@author Jessica Pereira

@description Initial PT or Case number + description of what the class does 

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields 
*/
global class updateQuantityOrdered_SubscribedProducts implements Database.Batchable < sObject > {

	String query;
	global updateQuantityOrdered_SubscribedProducts() {
		query = 'Select Id, NextRefreshDate__c, Enqix_BID_Location_Limit_Period__c, quantityOrdered__c, Account__c, Product__c from Subscribed_Products__c where Enqix_BID_Location_Limit_Quantity__c < 40000 and Enqix_BID_Location_Limit_Quantity__c != null and NextRefreshDate__c != null';

	}

	global Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	global void execute(Database.BatchableContext BC, List < Subscribed_Products__c > scope) {
		system.debug('0. Subscribed Products that have Limit < 40000, and NRD != null: ' + scope.size() + ' = \n'+scope );

		Set < Id > accounts = new Set < Id > ();
		Set < Id > products = new Set < Id > ();
		for (Subscribed_Products__c s: scope) {
			accounts.add(s.Account__c);
			products.add(s.Product__c);
		}
		
		List < OrderItem > allOrderswithProductAndAccount = [Select id, Product2Id, Order.AccountId, Order.Delivery_Date__c , Quantity
			FROM OrderItem WHERE 
			Product2Id in: products and 
			Order.AccountId in: accounts
		];
		system.debug('#Order Items connected to those SP\'s:' +allOrderswithProductAndAccount.size());

		for (Subscribed_Products__c sb: scope) {
			system.debug('1. SP\'s ID: ' + sb.Id + ' | Next Refresh Date: ' + sb.NextRefreshDate__c + 'Set Subscribed Product\'s quantity Ordered to 0. Start counting now...');
			//system.debug('' );
			sb.quantityOrdered__c = 0;

			Date previousNextRefreshDate = sb.NextRefreshDate__c;
			
			if (sb.Enqix_BID_Location_Limit_Period__c == 'Annual') {
				previousNextRefreshDate = Date.newInstance(previousNextRefreshDate.year() - 1, previousNextRefreshDate.month(), previousNextRefreshDate.day());
			} else if (sb.Enqix_BID_Location_Limit_Period__c == 'Monthly') {
				previousNextRefreshDate = Date.newInstance(previousNextRefreshDate.year(), previousNextRefreshDate.month() - 1, previousNextRefreshDate.day());
			} else if (sb.Enqix_BID_Location_Limit_Period__c == 'Quaterly') {
				previousNextRefreshDate = Date.newInstance(previousNextRefreshDate.year(), previousNextRefreshDate.month() - 3, previousNextRefreshDate.day());
            //Jira 1947 -- add new option "Half-year" to the picklist Enqix_BID_Location_Limit_Period__c
			} else if (sb.Enqix_BID_Location_Limit_Period__c == 'Half-year') {
				previousNextRefreshDate = Date.newInstance(previousNextRefreshDate.year(), previousNextRefreshDate.month() - 6, previousNextRefreshDate.day());
            }
			system.debug('2. Previous Next Refresh Date: ' + previousNextRefreshDate);
			
			for (OrderItem oi: allOrderswithProductAndAccount) {
				//TODO Change this 29/10/2018 , instead of CreatedDate, put DeliveryDate  Delivery_Date__c 
				if (sb.Account__c == oi.Order.AccountId && sb.Product__c == oi.Product2Id && oi.Order.Delivery_Date__c > previousNextRefreshDate ) {
					system.debug('3.1 Found a subscribed product that has order item: '+ oi);
					sb.quantityOrdered__c += oi.Quantity;
					system.debug('3.2. Updated quantity ordered. New sp\'s value:' + sb.quantityOrdered__c);
				}
			}
			system.debug('4. END.');
		}
		update scope;
		//update allOrderswithProductAndAccount;
	}

	global void finish(Database.BatchableContext BC) {

	}

}