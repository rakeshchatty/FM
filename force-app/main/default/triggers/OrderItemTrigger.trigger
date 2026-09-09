//Jira 1906 - Changes made to make code more efficient (line 48 / 54 / 63/ 120) 15-03-2021
//@modifications 03.02.2022 "Order Save behaviour" release - make necessary changes
trigger OrderItemTrigger on OrderItem (before insert, after insert, before update, after update, before delete, after delete) {
    
    OrderItemTriggerHandler.handleTrigger(Trigger.new, Trigger.oldMap, Trigger.operationType);

    public static boolean AfterInsertHasRun = false;
    
    if ((Trigger.IsAfter && Trigger.IsInsert) || (Trigger.IsAfter && Trigger.IsUpdate)) {
        
        List<OrderItem> listaA = new List<OrderItem>();
        //Mudanças no Order
        //14.12.2018 -> Only populates the Partner Total Price if the discount to apply is Partner
        for(OrderItem o : Trigger.new){
            if(o.Discount_to_Apply__c == 'Partner'){
                listaA.add(o);
            }
        }
        OrderItemTriggerHelper helper = new OrderItemTriggerHelper();
        if (Trigger.IsInsert) {
            if(listaA.size() > 0){
                helper.populatePartnerTotalAmount(listaA, true);
            }
            helper.updateSubscribedProducts(trigger.newMap, trigger.oldMap, true);
        }
        else {
            if(listaA.size() > 0){
                helper.populatePartnerTotalAmount(listaA, false);
            }
            helper.updateSubscribedProducts(trigger.newMap, trigger.oldMap, false);
        }
    }
    if (Trigger.IsDelete && Trigger.IsBefore || Trigger.IsDelete && Test.isRunningTest()) {
        new OrderItemTriggerHelper().subtractQuantityOrdered(trigger.oldMap);
        // if (!UserInfo.getUserName().contains('integration@thefirstmile.co.uk') && !UserInfo.getUserName().contains('customer.portal@thefirstmile.co.uk')) {
        //     List<OrderItem> orderItemError = [SELECT Id FROM OrderItem WHERE Id IN :Trigger.old AND (Order.Detrack_Status__c = 'In Progress' OR Order.Status = 'Invoiced')];
        //     for (OrderItem orderItem : orderItemError) {
        //         Trigger.oldMap.get(orderItem.Id).addError('You cannot delete this OrderProduct because the Detrack Status is In Progress or the Order is already Invoiced.');
        //     }
        // }
    }

    // BEGIN TODO - 991 JIRA
    List<OrderItem> listaB = new List<OrderItem>();

    if(Trigger.IsBefore && ( Trigger.IsUpdate || Trigger.IsInsert ) ){  
  
        List<OrderItem> populateTotalDiscount = new List<OrderItem>();
        List<OrderItem> populateSupplierFields = new List<OrderItem>();
        List<OrderItem> populatePricebookEntry = new List<OrderItem>();
        set<Id> OrderIds = new set<Id>();
        set<Id> productIds = new set<Id>();
        set<Id> pricebookIds = new set<Id>();
        OrderItemTriggerHelper helper = new OrderItemTriggerHelper();
        
        //14.12.2018 -> Only populates the Partner Unit Price if the discount to apply is Partner
        for(OrderItem o : Trigger.new){
            OrderIds.add(o.OrderId);

            if (o.PricebookEntryId == null){
                populatePricebookEntry.add(o);
                productIds.add(o.Product2Id);
                pricebookIds.add(o.Price_Book__c);
            }
            if (o.PricebookEntryId != null){
                populateTotalDiscount.add(o);
            }           
            if (o.Is_supplier_Order_Prod__c == true || o.Supplier__c != null){
                populateSupplierFields.add(o);
            }
            if(o.Discount_to_Apply__c == 'Partner'){
                listaB.add(o);
            }
            if (o.Delivery_Type__c != 'Delivery'){
                o.Standard_check__c = 1;
            }
        }
        
        if(populatePricebookEntry.size() > 0){
            helper.populatePricebookEntryId(populatePricebookEntry, productIds, pricebookIds);
        }
        if(populateTotalDiscount.size() > 0){
            helper.populateTotalDiscount(populateTotalDiscount);
        }        
        if(populateSupplierFields.size() > 0){
            helper.populateSupplierFields(populateSupplierFields, Trigger.IsUpdate);
        }
        if(listaB.size() > 0){
            helper.populateParterUnitPrice(listaB);
        }
        OrderItemTriggerHelper.orderProductsValidation(OrderIds, Trigger.new);
    }
    
    if(Trigger.IsBefore && Trigger.IsInsert){
        
        List<OrderItem> populateDiscountFields = new List<OrderItem>();
        OrderItemTriggerHelper helper = new OrderItemTriggerHelper();
        
        for (OrderItem oi : Trigger.new){
            system.debug('Account_Discount__c --> ' +oi.Account_Discount__c);
            system.debug('Discount_to_apply__c --> ' +oi.Discount_to_apply__c);
            //When adding a new order product to an Order already created
            if (((oi.Discount__c == null || oi.Discount__c == 0) && oi.Account_Discount__c == null && oi.Discount_to_apply__c == 'Account') || ((oi.Partner_Discount__c == null || oi.Partner_Discount__c == 0) && oi.Account_Discount__c == null && oi.Discount_to_apply__c == 'Partner')){
                populateDiscountFields.add(oi);
            }
        }
        
        if(populateDiscountFields.size() > 0){
            helper.populateDiscountField(populateDiscountFields);
        }
    }
    
    if (Trigger.IsAfter && Trigger.IsInsert){
        Map <Id, List<OrderItem>> ordOItemsMap = new Map <Id, List<OrderItem>>();
        for(OrderItem oi : trigger.new){
            if(ordOItemsMap.containsKey(oi.OrderId)){
                ordOItemsMap.get(oi.OrderId).add(oi);
            }else{
                ordOItemsMap.put(oi.OrderId,new List<orderItem>{oi});
            }        
        }
        OrderItemTriggerHelper helper = new OrderItemTriggerHelper();
        helper.updateOrderSummary(ordOItemsMap); 
    }   
}