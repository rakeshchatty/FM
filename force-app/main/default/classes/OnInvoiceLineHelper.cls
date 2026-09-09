/** 
(c) 2018 Nexell GmbH / Rolling-Space
Developed by Nexell GmbH, Zug (Switzerland) / Rolling-Space, Braga (Portugal)
@date Date of creation mm.yyyy 
@author Name of initial developer 

@description Initial PT or Case number + description of what the class does 

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields 
*/
public with sharing class OnInvoiceLineHelper {
	// Trigger entry point   
	public static void entry(  
								System.TriggerOperation triggerEvent,
								List <Invoice_Line__c> newList,
								Map<Id, Invoice_Line__c> newMap,
								List <Invoice_Line__c> oldList,
								Map<Id, Invoice_Line__c> oldMap 
							) {
		// Dispatch trigger event to corresponding methods 
		switch on triggerEvent {
            when BEFORE_DELETE {
                List <SageExtract__c> sageExtractToDelete = new List <SageExtract__c>();
                if(!test.isRunningTest()){
                    for(Invoice_Line__c il: [Select id, (Select Id from SageExtracts__r) from Invoice_Line__c where id in :oldList]){
                        sageExtractToDelete.addAll(il.SageExtracts__r);   
                    } 
                    if(sageExtractToDelete.size() > 0){
                        delete sageExtractToDelete;
                    }
                }
            }
			when AFTER_INSERT {
				List < LogRegister > logs = new List < LogRegister > ();
				List < Database.SaveResult > results;
				List < sObject > records;
				String process;
				String action;
				String sObjectType;
				String ParentField;
				system.debug('invoice line after insert');
				Map<Id, Order> ordersToUpdate = new Map<Id, Order>();
				Set<Id> orderIds = new Set<Id>();
				for (Invoice_Line__c i : newList) {
					orderIds.add(i.Order__c);
				}
				Map<Id, Order> orders = new Map<Id,Order>([SELECT Id, Invoice_Created__c, CreditCard_Payment__c, PaymentReference__c, Invoice__c, PartnerInvoice__c FROM Order WHERE ID In :orderIds]);
				system.debug('Orders Related to invoice lines: ' + orders);
				Map<Id, Invoice_Header__c> headersMap = new Map<Id, Invoice_Header__c>([SELECT Id, Generate_Payment__c, Payment_Reference__c, IsPartnerHeader__c FROM Invoice_Header__c WHERE Id IN (SELECT Invoice_HeaderId__c FROM Invoice_Line__c WHERE Id IN :newMap.keySet())]);
				//Map<Id, Invoice_Header__c> headersToUpdate = new Map<Id, Invoice_Header__c>();
                for (Invoice_Line__c i : newList) {
					system.debug('debuging invoice line after insert: ' + i.Order__c);
					if (i.Order__c != null && orders.containsKey(i.Order__c)) {
						system.debug('Updating order on after inv line insert');
						Order o = orders.get(i.Order__c);
                        Invoice_Header__c inv = headersMap.get(i.Invoice_HeaderId__c);
                        o.Invoice_Created__c = true;
                        o.Status = 'Invoiced';

                        if (inv.IsPartnerHeader__c) {
                            if (o.PartnerInvoice__c == null) {
                                o.PartnerInvoice__c = i.Invoice_HeaderId__c;
                            }
                        } else {
                            if (o.Invoice__c == null) {
                                o.Invoice__c = i.Invoice_HeaderId__c;
                            }
                        }
						system.debug('order ccp: '+o.CreditCard_Payment__c);
						system.debug('order pr: '+o.PaymentReference__c); 
						/* Bruno - 14-01-2019 - 1215 - Create Payments for Invoices paid by Card on CP */
						/* Bruno - 14-03-2019 - 1215 - Changed the validation fields for suspecting it doesn't get filled in until the transaction ends, as it is a formula field */
						/* Joao  - 08/05/2019 - 1215 - Removed '&& !headersToUpdate.containsKey(i.Invoice_HeaderId__c)' from the condittion. Seems that no invoice are beeing updated but the order are */
						/*if (o.Order2__r.CreditCard_Payment__c) {
							system.debug('Got inside if condition. Setting invoice to be payed by Card: '+i.Invoice_HeaderId__c); 
							Invoice_Header__c inv = headersMap.get(i.Invoice_HeaderId__c);
							//inv.Generate_Payment__c = true;
							//inv.PaymentReference__c = o.Order2__r.Payment_Reference__c;
							headersToUpdate.put(inv.Id, inv);
						}*/
						
						ordersToUpdate.put(o.Id, o);
                        system.debug('ordersToUpdate'+ordersToUpdate.size());
					}
				}
				system.debug('Orders to update: ' + ordersToUpdate);
				if (ordersToUpdate.values().size() > 0) {
					System.debug('Saving updated orders.');
					//update ordersToUpdate.values();
					Database.UpsertResult[] srList = Database.upsert(ordersToUpdate.values(), false);
					system.debug('srList: '+srList);
					records = ordersToUpdate.values();
					process = 'OnInvoiceLineHelper upsert ordersToUpdate.values()';
					action = 'Upsert';
					sObjectType = 'Order';
					ParentField = 'AccountId';

					LogRegister.createLogsUpsert(srList, records, process, action, sObjectType, ParentField);
				}
			}    
	  	}  
	}
}