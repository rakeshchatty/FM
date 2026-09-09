/**
(c) 2018 XPAND-IT
Developed by XPAND-IT
@date Date of creation: February 2019
Date of updates:

@modifications Feb/2019 [JIRA 978] - Generation of Credit Notes from an invoice
*/
 public class XpandIT_CreditNote_Controller {

    @AuraEnabled
    public static string getInvoiceResumeData(Id invoiceID){
        Invoice_Header__c invoice = [SELECT Id, Account__c, InvoiceFrequency__c, InvoiceNo__c FROM Invoice_Header__c WHERE Id = :invoiceID limit 1];
        Boolean isLONCreditNote = invoice.InvoiceNo__c.contains('LON');
        return ''+invoice.Account__c+'/'+invoice.InvoiceFrequency__c+'/'+isLONCreditNote;
    }

    @AuraEnabled
    public static List<Account> getAccountsLocations(ID invoiceID, ID accountID){
        List<Invoice_Line__c> invoicesLines = [SELECT Id, Location_Id__c FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :invoiceID];
        List<ID> locationsIDs = new List<ID>();
        for(Invoice_Line__c invLine :invoicesLines)
        {
            locationsIDs.add(invLine.Location_Id__c);
        }
        List<Account> invociesLocations = [SELECT Id, Name, Partnership__c FROM Account WHERE (ParentId = :accountID OR Partnership__c = :accountID) AND ID iN :locationsIDs ORDER BY Name];
        if (invociesLocations.size() == 0)
        {
            throw new AuraHandledException('The location on this invoice is no longer on the parent account which the invoice is on. Please move the location back to the account of the invoice, issue the credit then move the location back to the new parent account.');
        }
        return invociesLocations;
    }

    @AuraEnabled
    public static List<Order> getLocationsOrders(ID invoiceID, ID locationID){
        List<Invoice_Line__c> invoicesLines = [SELECT Id, Order__c FROM Invoice_Line__c WHERE Invoice_HeaderId__c = :invoiceID AND Location_Id__c = :locationID];
        List<ID> ordersIDs = new List<ID>();
        for(Invoice_Line__c invLine :invoicesLines)
        {
            ordersIDs.add(invLine.Order__c);
        }
        List<Order> locationsOrders = [SELECT Id, OrderNumber FROM Order WHERE Order.ID IN :ordersIDs];
        return locationsOrders;
    }

    @AuraEnabled    
     public static List<OrderItem> generateCreditOrder(Id invoiceID, Id OrderID)
     {
         Order order = [SELECT Id FROM Order WHERE Id =: OrderID Limit 1];
         Invoice_Header__c invoice = [SELECT Id, Name, Account__c, OrderId__c, OrderIds__c, Location__r.Price_book__c, Account__r.Price_book__c,
                                      (SELECT ID, Name, InvoiceNoLine__c, InvoiceStatus__c, Description__c,Amount__c, Invoice_HeaderId__c, Location_Id__c, Qty__c, UnitPrice__c, Product__c, Product_Name__c FROM Invoice_Lines__r WHERE Order__c = :order.Id) 
                                      FROM Invoice_Header__c Where Id = :invoiceID limit 1];
         //jira 1883 - fix nas orders que estavam a ser inseridas sem produtos devido ao Produto não estar relacionado com o Pricebook que pertence à Invoice que gera a CreditNote.
         List <PricebookEntry> pricebookEntries = new list <PricebookEntry>();
		 Account acc;
         order = [SELECT Id, Pricebook2Id FROM Order WHERE Id = :orderId];
         if(invoice.Location__c != null){
         	pricebookEntries = [Select Id, Product2Id, Product2.Name from PricebookEntry where Pricebook2ID =: order.Pricebook2Id];
         }else{
            pricebookEntries = [Select Id, Product2Id, Product2.Name from PricebookEntry where Pricebook2ID =: order.Pricebook2Id]; 
         }
         List <string> entriesIds = new List <string>();
         for(PricebookEntry entries: pricebookEntries){
             entriesIds.add(entries.Product2Id);
         }
         List<OrderItem> ordProds = new List<OrderItem>();
         for(Invoice_Line__c invLine :invoice.Invoice_Lines__r)
         {
             if(entriesIds.contains(invLine.Product__c)){
                 OrderItem ordProd = new OrderItem(
                     Manual_Product_Name__c = invLine.Product_Name__c,
                     Product2Id = invLine.Product__c,
                     Quantity = invLine.Qty__c,
                     ListPrice__c = invLine.UnitPrice__c,
                     Credit_Note_line__c = true
                 );
                 ordProds.add(ordProd);
             }
         }
          return ordProds;
     }

    @AuraEnabled    
    public static List<OrderItem> generateCreditOrder(Id invoiceID)
    {
        Invoice_Header__c invoice = [SELECT Id, Location__r.Price_book__c, Name, Account__c, OrderId__c, OrderIds__c, (SELECT ID, Name, InvoiceNoLine__c, InvoiceStatus__c, Description__c,Amount__c, Invoice_HeaderId__c, Location_Id__c, Qty__c, UnitPrice__c,Product__c FROM Invoice_Lines__r ) FROM Invoice_Header__c Where Id = :invoiceID limit 1];
        //jira 1883 - fix nas orders que estavam a ser inseridas sem produtos devido ao Produto não estar relacionado com o Pricebook que pertence à Invoice que gera a CreditNote.
        List <PricebookEntry> pricebookEntries = [Select Id from PricebookEntry where Pricebook2ID =: invoice.Location__r.Price_book__c];
        List<OrderItem> ordProds = new List<OrderItem>();
        for(Invoice_Line__c invLine :invoice.Invoice_Lines__r)
        {
            OrderItem ordProd = new OrderItem(
                                                Manual_Product_Name__c = invLine.Description__c,
                                                Product2Id = invLine.Product__c,
                                                Quantity = invLine.Qty__c,
                                                ListPrice__c = invLine.UnitPrice__c,
                								Credit_Note_line__c = true
            );
            ordProds.add(ordProd);
        }
        return ordProds;
    }

	@AuraEnabled
	 public static Boolean createCreditOrder(List<OrderItem> creditOrdProds, String notes, Id invoiceId, Id locationID, Boolean creditPartner) {
		if (creditOrdProds.isEmpty()) {
            return false;
        }
 
        Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true].Id;
        if (!creditPartner) {
			Order creditOrder = new Order(
				Driver_Notes__c = notes,
				AccountId = locationID,
				Order_Placed_Date__c = system.today(),
				EffectiveDate = system.today(),
				Type = 'Invoicing',
				Status = 'Draft',
				Original_Invoice_to_Credit__c = invoiceId,
				PO_Number__c = 'Credit Note',
				Pricebook2Id = standardPricebookId
			);
			INSERT creditOrder;

			Product2 creditProd = [SELECT Id, Name FROM Product2 WHERE Name = 'Non-standard Other Charge/Credit' LIMIT 1];
			for (OrderItem credOrdProd : creditOrdProds) {
				credOrdProd.Product2Id = creditProd.Id;
				credOrdProd.OrderId = creditOrder.Id;
				credOrdProd.Price_Book__c = standardPricebookId;
				credOrdProd.Quantity = credOrdProd.Quantity*(-1);
				credOrdProd.Credit_Note_line__c = true;
			}

			INSERT creditOrdProds;
			return true;
		 } else {
            Invoice_Header__c invoice = [SELECT Account__c, Account__r.RecordTypeId FROM Invoice_Header__c WHERE Id = :invoiceId LIMIT 1];
            if (invoice.Account__r.RecordTypeId != AccountUtil.RECORDTYPEID_PARTNER) {
                throw new AuraHandledException('If you want to credit a Partner Account, you must generate the "Credit Note" on a Partner Invoice.');
            }
            Order creditOrder = new Order (
                Driver_Notes__c = notes,
                AccountId = invoice.Account__c,
                Order_Placed_Date__c = System.today(),
                EffectiveDate = System.today(),
                Type = 'Invoicing',
                Status = 'Draft',
                Original_Invoice_to_Credit__c = invoiceId,
                PO_Number__c = 'Credit Note',
                Pricebook2Id = standardPricebookId
            );
            INSERT creditOrder;
            Product2 creditProd = [SELECT Id, Name FROM Product2 WHERE Name = 'Non-standard Other Charge/Credit' LIMIT 1];
            for (OrderItem credOrdProd:creditOrdProds) {
                credOrdProd.Product2Id = creditProd.Id;
                credOrdProd.OrderId = creditOrder.Id;
                credOrdProd.Price_Book__c = standardPricebookId;
                credOrdProd.Quantity = credOrdProd.Quantity*(-1);
                credOrdProd.Credit_Note_line__c = true;
            }
            INSERT creditOrdProds;
            return true;
		 }
	 }

    @AuraEnabled
    public static Boolean createSimpleCreditOrder(Decimal amount, String notes, Id invoiceId, Id locationID) {
		Id standardPricebookId = [SELECT Id FROM Pricebook2 WHERE IsStandard = true].Id;
        Order creditOrder = new Order(
            Driver_Notes__c = notes,
            AccountId = locationID,
            Order_Placed_Date__c = System.today(),
            EffectiveDate = System.today(),
            Type = 'Invoicing',
            Status = 'Draft',
            Original_Invoice_to_Credit__c = invoiceId,
            PO_Number__c = 'Credit Note',
            Pricebook2Id = standardPricebookId
        );
        INSERT creditOrder;

        Product2 creditProd = [SELECT Id, Name FROM Product2 WHERE Name = 'Non-standard Other Charge/Credit' LIMIT 1];
        OrderItem creditOrderProduct = new OrderItem(
            Product2Id = creditProd.Id,
            Manual_Product_Name__c = notes,
            Quantity = -1,
            ListPrice__c = amount,
            OrderId = creditOrder.Id,
            Price_Book__c = standardPricebookId,
            Credit_Note_line__c = true
        );
        INSERT creditOrderProduct;
        return true;
    }
}