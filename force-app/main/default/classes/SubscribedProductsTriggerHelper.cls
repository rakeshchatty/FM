public with sharing class SubscribedProductsTriggerHelper {

	
	public void populateQuantityOrdered(List < Subscribed_Products__c > subcribed_products) {
		List < Subscribed_Products__c > updateList = new List < Subscribed_Products__c > ();
		//This list needs to be updated because it is being ran for AFTER insert on the trigger, to update the quantityOrdered.
		Set < Id > subscribedProductsIds = new Set < Id > ();
		//To take the select out of the loop, needs to be created 2 set of id's, product id and account id 
		Set < Id > productIds = new Set < Id > ();
		Set < Id > accountIds = new Set < Id > ();

		for (Subscribed_Products__c p: subcribed_products) {
			subscribedProductsIds.add(p.Id);
			productIds.add(p.Product__c);
			accountIds.add(p.Account__c);
		}
		system.debug('TAMANHO LISTA PRODUCTS ' + productIds.size());
		system.debug('Tamanho Lista Accounts ' + accountIds.size());

		List < Subscribed_Products__c > subscribedProductsData = [SELECT NextRefreshDate__c, StartDate__c, Account__r.Enqix_Location_ID__c,
			Account__r.RecordType.DeveloperName, Product__r.Enqix_Id__c, Product__r.Name, quantityOrdered__c, Product__c
			FROM Subscribed_Products__c WHERE Id IN: subscribedProductsIds];

		List < OrderItem > allOrderLines = [SELECT Id, CreatedDate, Quantity, Product2Id, Order.AccountId
			FROM OrderItem WHERE Product2Id in: productIds and Order.AccountId in: accountIds];
		//Debugs
		system.debug('------> Quantas OrderItems que tem em comum o Product e Account dos Subscribed Products? ->' + allOrderLines.size());
		for (Id pid: productIds) {
			system.debug('Id do produto-> ' + pid);
		}
		for (Id aid: accountIds) {
			system.debug('Id da Conta-> ' + aid);
		}

		for (Subscribed_Products__c p: subscribedProductsData) {
			if (p.quantityOrdered__c == null) p.quantityOrdered__c = 0;
			system.debug('Entrou um novo Subscribed Product! quantity ordered = ' + p.quantityOrdered__c);
			for (OrderItem i: allOrderLines) {
				/* Bruno - 11.02.2019 -> 1365 */
				if(i.CreatedDate > p.StartDate__c /*&& i.Product2Id == p.Product__c*/){ //CHanged Here to do this.
					system.debug('Para cada nova OrderItem incrementa a quantidade.\n Só Para Order Items criados após Start Date do S.B. ');
					p.quantityOrdered__c += i.Quantity;
					system.debug('Quantidade desta OrderItem --> ' + i.Quantity);
				}
				
			}
			updateList.add(p);
			system.debug('Nova quantity Ordered = ' + p.quantityOrdered__c);
		}


		if (updateList.size() > 0) {
			system.debug('updatelist::::' + updateList);
			Map<Id,Subscribed_Products__c> removeD = new Map<Id, Subscribed_Products__c>();
			for(Subscribed_Products__c ppp : updateList){
				removeD.put(ppp.Id, ppp);
			}
			List<Subscribed_Products__c> updateListWithoutDups = new List<Subscribed_Products__c>(removeD.values());
			update updateListWithoutDups;
		}
	}

	public void updateData(List < Subscribed_Products__c > lista) {
		boolean hasChanged = false;
		for (Subscribed_Products__c p: lista) {
			hasChanged = updateQuantityOrdered(p);


			if (hasChanged) {
				updateNextRefreshDate(p);
			}
			if (p.NextRefreshDate__c == null) {
				populateFirstNextRefreshDate(p);
			}
		}
	}


	public void updateNextRefreshDate(Subscribed_Products__c p) {
		switch on p.Enqix_BID_Location_Limit_Period__c {
			when 'Annual' {
				p.NextRefreshDate__c = Date.newInstance(p.NextRefreshDate__c.year() + 1, p.NextRefreshDate__c.month(), p.NextRefreshDate__c.day());
			}
			when 'Quarterly' {
				p.NextRefreshDate__c = Date.newInstance(p.NextRefreshDate__c.year(), p.NextRefreshDate__c.month() + 3, p.NextRefreshDate__c.day());
			}
			when 'Monthly' {
				p.NextRefreshDate__c = Date.newInstance(p.NextRefreshDate__c.year(), p.NextRefreshDate__c.month() + 1, p.NextRefreshDate__c.day());
			}
            //Jira 1947 -- add new option "Half-year" to the picklist Enqix_BID_Location_Limit_Period__c
            when 'Half-year' {
				p.NextRefreshDate__c = Date.newInstance(p.NextRefreshDate__c.year(), p.NextRefreshDate__c.month() + 6, p.NextRefreshDate__c.day());
			}
		}
	}


	public void populateFirstNextRefreshDate(Subscribed_Products__c p) {
		system.debug('Attempting to populate the Next Refresh Date');
		if(p.StartDate__c == null){
			system.debug('Could not populate Next Refresh Date because the Start Date is null. Please fill the Start Date.');
			return;
		}
		
		switch on p.Enqix_BID_Location_Limit_Period__c {
			when 'Annual' {
				system.debug('p.StartDate__c ' + p.StartDate__c );
				p.NextRefreshDate__c = Date.newInstance(p.StartDate__c.year() + 1, p.StartDate__c.month(), p.StartDate__c.day());
				
			}
			when 'Quarterly' {
				p.NextRefreshDate__c = Date.newInstance(p.StartDate__c.year(), p.StartDate__c.month() + 3, p.StartDate__c.day());
			}
			when 'Monthly' {
				p.NextRefreshDate__c = Date.newInstance(p.StartDate__c.year(), p.StartDate__c.month() + 1, p.StartDate__c.day());
			}
		}
		if(p.NextRefreshDate__c != null){
			system.debug('Next Refresh Date populated!');
		} 
	}

	public boolean updateQuantityOrdered(Subscribed_Products__c p) {
		boolean flag = false;
		if (p.NextRefreshDate__c <= system.today()) {
			p.quantityOrdered__c = 0;
			flag = true;
		}
		return flag;
	}


	

}