//@modifications 01.02.2022 "Order Save behaviour" release - make necessary changes
////@modifications 03.02.2022 "Order Save behaviour" release - Comment process that updates the field FIRST_EVER_ORDER__c
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
                system.debug('recurring? '+o.Recurring__c);
                if (o.RecurringId__c != null){
                    insertOrderProductsForRecurrings.add(o);
                }
            }
            system.debug('accIds -->' + accIds);
            if(accIds.size() > 0){
                AccountTriggerHelper.updateAcc(accIds);
            }
            if (sfOrders.size() > 0) {
                OrderTriggerHelper.updateOrderNumber(Trigger.New);
            } 
            system.debug('insertOrderProductsForRecurrings -->' + insertOrderProductsForRecurrings.size());
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
   
    //06.12.2018 Jessica JIRA 1196
    if(trigger.isBefore && trigger.isUpdate){
        Id fmSupplierId = [SELECT Id FROM Suppliers__c WHERE Name = 'First Mile Ltd' LIMIT 1].Id;
        for(Order o: trigger.new){
            system.debug('UserInfo.getUserId()-->'+UserInfo.getUserId());
            
            if(o.is_Salesforce__c && o.Type == 'Regular' && o.POD_Delivery_Date__c != null && Trigger.oldMap.get(o.Id).POD_Delivery_Date__c != o.POD_Delivery_Date__c){
                system.debug('I found an order that is from Salesforce, is of type regular and has POD_Delivery_Date != null and that in which this same date has been changed.');
                o.Delivery_Date__c = o.POD_Delivery_Date__c;
                
            }  //1

            if(o.is_Salesforce__c && o.Type == 'Invoicing' && o.PO_Number__c == 'WheelieBinOrder0' && o.Delivery_Date__c == null){
                system.debug('I found an order SF, Type Invoicing, PO Number WheelieBinOrder0 and Delivery Date null');
                o.Delivery_Date__c = o.Requested_Delivery_Date__c; 
            } //2

            if(o.is_Salesforce__c && o.Type == 'Invoicing' && o.PO_Number__c != 'WheelieBinOrder0' && o.Delivery_Date__c == null){
                system.debug('I found an order SF, Type Invoicing, PO Number != WheelieBinOrder0 and Delivery Date null');
                o.Delivery_Date__c = o.CreatedDate.date(); 
            } //3

            if(o.is_Salesforce__c && o.Type == 'Contractor' && o.Delivery_Date__c == null){
                system.debug('I found an order SF, Type Invoicing, PO Number != WheelieBinOrder0 and Delivery Date null'); 
                o.Delivery_Date__c = o.Requested_Delivery_Date__c; 
            } //4
            
            //07-01-2022 --> jira 1912 -- Update SyncedwithCP to false if the user that modified the record was the CP user
            if (UserInfo.getName() == 'Customer Portal' && Trigger.oldMap.get(o.Id).syncedwithcp__c == TRUE && Trigger.oldMap.get(o.Id).Status != Trigger.newMap.get(o.Id).Status){
                o.syncedwithcp__c = false;
            }
            //Update Delivery Status & Status field based on Order Type
            if (o.Type == 'Invoicing' && o.Number_of_Order_Products__c > 0 && Trigger.oldMap.get(o.Id).Status != 'Delivered' && Trigger.oldMap.get(o.Id).Status != 'Invoiced' && o.Status != 'Invoiced') {
                o.Status = 'Delivered';
                o.Delivery_Status__c = 'Delivered';
            }
            Boolean isFMSupplier = String.isBlank(o.Supplier__c) || o.Supplier__c == fmSupplierId;
            if (o.Type == 'Contractor' && o.Number_of_Order_Products__c > 0 && Trigger.oldMap.get(o.Id).Status != 'Delivered' && Trigger.oldMap.get(o.Id).Status != 'Invoiced' && o.Status != 'Invoiced' && o.Status != 'Delayed Confirmation'
                && (isFMSupplier || (!isFMSupplier && o.OrderProductsToChargeVariableWeight__c == 0))) {
                o.Status = 'Delivered';
                o.Delivery_Status__c = 'Delivered';
            }
        }        
    }
    //END Jessica JIRA 1196
  
    if (Trigger.IsAfter && Trigger.IsUpdate) { 

        List < Order > scope = new List < Order > ();
        List < Order > scopeCreateCN = new List < Order > ();
        List < Order > checkProductSkin = new List < Order > ();
        List < Order > bidOrders = new List < Order > ();

        for (Order ord: trigger.new) {
             
            system.debug('Partner Total Amount - '+ ord.Partner_Total_Amount__c);
            //Done by Zac's team BEGIN
            /*if (ord.is_Salesforce__c && trigger.oldMap.get(ord.Id).EffectiveDate != ord.EffectiveDate || trigger.OldMap.get(Ord.Id).TotalAmount != ord.TotalAmount) {
                AccountIds.add(ord.AccountId);
            }*/
            //Done by Zac's team END

            //BEGIN Create Invoices for ORDERS  - Per Order Invoices and BID Invoices
            /* Bruno 08.01.2019 - 1233 - added the check for Created Later field to create invoices for orders created as Delivered */
            //Only create Invoices if the Order has OrderItems related
            System.debug('Number_of_Order_Products__c --> '+ord.Number_of_Order_Products__c);
            System.debug('Created_Later__c --> '+ord.Created_Later__c);
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
                    scopeCreateCN.add(ord);
                    checkProductSkin.add(ord);
                }
            }
            //END Create Compliance Documents
        }    
        
        if (scope.size() > 0) {
            Invoicing.convert(scope);
        }  
        /*if (bidOrders.size() > 0) {
            system.debug(bidOrders);
            Set < Id > orderIds = new Set < Id > ();
            for (Order o: bidOrders) {
                orderIds.add(o.Id);
            }
            OrderTriggerHelper.createInvoiceBID(orderIds);
        }*/
        if (scopeCreateCN.size() > 0) {
            Set < Id > orderIds = new Set < Id > ();
            for (Order o: checkProductSkin) {
                orderIds.add(o.Id);
            }

            if (System.isFuture()) {
                OrderTriggerHelper.createConsignmentNotes(orderIds);
            } else {
                OrderTriggerHelper.createConsignmentNotesFuture(orderIds);
            }            
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