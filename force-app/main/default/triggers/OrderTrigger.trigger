trigger OrderTrigger on Order(before insert, after insert,before update, after update) {

	List<LogRegister> logs = new List<LogRegister>();
	List<Database.SaveResult> results;
	List<sObject> records;
	String process;
	String action;
	String sObjectType;
	String ParentField;

	set < Id > AccountIds = new set < Id > ();

	//26.11.2018 Changed query inside helper to fix bug. Was not populating Enqix ID accordingly.
	if (trigger.isinsert) {
		//TODO 1079, after insert Order, update Enqix ID = OrderNumber.
		if (trigger.isAfter) {
			//Bruno 05-12-2018 - only for SF generated Orders
			Set <Id> accIds = new Set<Id>();
			List <Order> sfOrders = new List <Order>();
			List <Order> insertOrderProductsForRecurrings = new List <Order>();
			for (Order o : Trigger.New) {
				if(o.Order_Account_ID__r.Collections__r.size() == 0){
					accIds.add(o.AccountId);
				}
				if (o.is_Salesforce__c) {
					sfOrders.add(o);
				}
				if (o.RecurringId__c != null){
					insertOrderProductsForRecurrings.add(o);
				}
			}
			if(accIds.size() > 0){
				AccountTriggerHelper.updateAcc(accIds);
			}
			if (sfOrders.size() > 0) {
				OrderTriggerHelper.updateOrderNumber(Trigger.New);
			}
			if (insertOrderProductsForRecurrings.size() > 0) {
				OrderTriggerHelper.insertOrderProductsForRecurrings(insertOrderProductsForRecurrings);
			}
		}
		//END 1079

		//28.11.2018 Jessica -> is Before [START]
		if (trigger.isBefore) {
			List < Order > list_StatusIsDelivered = new List < Order > ();
			for (Order o: Trigger.New) {
				if (o.Status == 'Delivered') {
					list_StatusIsDelivered.add(o);
				}
			}
			if (list_StatusIsDelivered.size() > 0) {
				OrderTriggerHelper.updateInsertedAsDelivered(list_StatusIsDelivered);
			}
		}
		//28.11.2018 Jessica -> is Before [FINISH]

	}

	if (Trigger.isBefore && Trigger.isUpdate) {
		for (Order order : Trigger.new) {
			Order oldOrder = Trigger.oldMap.get(order.Id);

			if (order.Type == 'Regular' && order.POD_Delivery_Date__c != null && oldOrder.POD_Delivery_Date__c != order.POD_Delivery_Date__c) {
				order.Delivery_Date__c = order.POD_Delivery_Date__c;
			}

			if (order.Delivery_Date__c == null) {
				if (order.Type == 'Invoicing') {
					order.Delivery_Date__c = (order.PO_Number__c == 'WheelieBinOrder0') ? order.Requested_Delivery_Date__c : order.CreatedDate.date();
				} else if (order.Type == 'Contractor') {
					order.Delivery_Date__c = order.Requested_Delivery_Date__c;
				}
			}

			String previousStatus = oldOrder.Status;
			//07-01-2022 --> jira 1912 -- Update SyncedwithCP to false if the user that modified the record was the CP user
			if (UserInfo.getName() == 'Customer Portal' && oldOrder.syncedwithcp__c == TRUE && previousStatus != order.Status) {
				order.syncedwithcp__c = false;
			}

			if (!order.IsVariableBilling__c && (order.Type == 'Invoicing' || (order.Type == 'Contractor' && !order.IsSalesforceRecurring__c)) && order.Number_of_Order_Products__c > 0
				&& previousStatus != 'Delivered' && previousStatus != 'Invoiced' && order.Status != 'Invoiced' && order.Status != 'Delayed Confirmation') {
					order.Status = 'Delivered';
					order.Delivery_Status__c = 'Delivered';
			}
		}
	}
	//END Jessica JIRA 1196

	if (Trigger.IsAfter && Trigger.IsUpdate) {

		List < Order > scope = new List < Order > ();
		List < Order > checkProductSkin = new List < Order > ();
		List < Order > bidOrders = new List < Order > ();

		for (Order ord: trigger.new) {
			//BEGIN Create Invoices for ORDERS  - Per Order Invoices and BID Invoices
			/* Bruno 08.01.2019 - 1233 - added the check for Created Later field to create invoices for orders created as Delivered */
			//Only create Invoices if the Order has OrderItems related
			if (ord.is_Salesforce__c && ((Trigger.oldMap.get(ord.Id).Status != 'Delivered' && ord.Status == 'Delivered') || (Trigger.oldMap.get(ord.Id).Created_Later__c == false && ord.Created_Later__c == true)) && ord.Invoice_Created__c == false) {
				scope.add(ord);
			}
			//END CREATE Invoices for ORDERS

			//BEGIN Create Compliance Documents: Consignment Notes and Secure Destructions
			/* Bruno - 11.02.2019 -> 1314 - removed the system.isbatch validation because methods are no longer future. */
			if (!System.IsBatch()) {
				/* Bruno - 29.01.2019 -> 1267 - Removed Is_Salesforce validation for the documents to be generated for both SF and Enqix orders */
				//jira 1894 -- change made so the new type of compliance documents do not enter this helper.
				if (((Trigger.oldMap.get(ord.Id).Status != 'Delivered' && ord.Status == 'Delivered') || (Trigger.oldMap.get(ord.Id).Created_Later__c == false && ord.Created_Later__c == true)) && !ord.Clearance_Order__c) {
					checkProductSkin.add(ord);
				}
			}
			//END Create Compliance Documents
		}

		if (scope.size() > 0) {
			Invoicing.convert(scope);
		}

		if (checkProductSkin.size() > 0) {
			Set < Id > orderIds = new Set < Id > ();
			for (Order o: checkProductSkin) {
				orderIds.add(o.Id);
			}

			if (System.isFuture()) {
				OrderTriggerHelper.createSecureDestructions(orderIds);
			} else {
				OrderTriggerHelper.createSecureDestructionsFuture(orderIds);
			}
		}
	}
}