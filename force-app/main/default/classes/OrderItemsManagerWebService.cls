//https://thefirstmile--integrate.my.salesforce.com/services/apexrest/OrderItems/
@RestResource(urlMapping='/OrderItems/*')
global with sharing class OrderItemsManagerWebService {
    private static Pricebook2 standardPriceBook;
    @HttpPost
    global static String handleOrderItem(String order_id, Decimal price) {
        try{          
            Order fetchOrder = new Order();
            fetchOrder = [SELECT Id,Pricebook2Id FROM Order WHERE Id =: order_id LIMIT 1];
            System.debug('fetchOrder found::::'+ fetchOrder);
            List<Product2> fetchProduct = new List<Product2>();
            fetchProduct = [SELECT id,Name FROM Product2 WHERE Name = 'Additional Waste' LIMIT 1];
            System.debug('product found::::'+ fetchProduct);
            if(fetchOrder.Pricebook2Id != null && fetchProduct.size() > 0){
                System.debug('**********product found*********');
                List<PricebookEntry> priceBookEntryObj = new List<PricebookEntry>();
                priceBookEntryObj = [SELECT Id,Name,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id =: fetchProduct[0].Id and Pricebook2Id =: fetchOrder.Pricebook2Id LIMIT 1];
                System.debug('price book entry::::'+ priceBookEntryObj);
                if(priceBookEntryObj.size() == 0){
                    System.debug('price book entry Not found::::'+ priceBookEntryObj.size());
                    List<PricebookEntry> checkOtherpriceBookEntry = new List<PricebookEntry>();
                    checkOtherpriceBookEntry = [SELECT Id,Name,Pricebook2Id,Product2Id FROM PricebookEntry WHERE Product2Id =: fetchProduct[0].Id LIMIT 1];
                    System.debug('PBE again check::::'+ checkOtherpriceBookEntry);
                    if(checkOtherpriceBookEntry.size() == 0){
                        System.debug('no entry found, please add standard price in standard price book first::::'+ checkOtherpriceBookEntry);
                        // Get the Standard Price Book ID
                        // Pricebook2 standardPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
                        Id standardPriceBookID = getStdPricebookId();
                        // Insert the Product in the Standard Price Book
                        PricebookEntry standardPriceBookEntry = new PricebookEntry(
                            Pricebook2Id = standardPriceBookID,
                            Product2Id = fetchProduct[0].Id,
                            UnitPrice = price,
                            UseStandardPrice = false,
                            IsActive = true
                        );
                        INSERT standardPriceBookEntry;
                        String newPriceBookEntryId = createPriceBookEntry(fetchProduct[0],fetchOrder,price);
                        if(newPriceBookEntryId != null){
                            //Add Order Item
                            Boolean flag = addOrderItem(order_id,newPriceBookEntryId,price,fetchOrder.Pricebook2Id);
                            if(flag){
                                return 'Order Item has been added successfully';
                            }
                        }
                    }else{
                        System.debug('entry found, no need to add standard price::::');
                        String newPriceBookEntryId = createPriceBookEntry(fetchProduct[0],fetchOrder,price);
                        if(newPriceBookEntryId != null){
                            //Add Order Item
                            Boolean flag = addOrderItem(order_id,newPriceBookEntryId,price,fetchOrder.Pricebook2Id);
                            if(flag){
                                return 'Order Item has been added successfully';
                            }
                        }
                    }
                }else{
                    System.debug('**********pricebook Entry present, you can now add the order Item**********');
                    Boolean flag = addOrderItem(order_id,priceBookEntryObj[0].Id,price,fetchOrder.Pricebook2Id);
                    if(flag){
                        return 'Order Item has been added successfully';
                    }
                }
            }else{
                System.debug('***********Product Not Found***************');
                return 'Product Not Found';
            }
            return '';
        }catch(Exception ex){
            System.debug('Exception is::::'+ex.getMessage()+'--in line:::'+ex.getLineNumber());
            return ex.getMessage();
        }
    }  
    public static Id createPriceBookEntry(Product2 fetchProduct, Order fetchOrder,Decimal price){
        try{
            System.debug('>>>>>create price book entry');
            //Create new pricebook entry containing pricebookId associated with Order and Product fetched
            PriceBookEntry newPriceBookEntry = new PriceBookEntry();
            newPriceBookEntry.Product2Id = fetchProduct.Id;
            newPriceBookEntry.Pricebook2Id = fetchOrder.PriceBook2Id;
            newPriceBookEntry.UnitPrice = price;
            newPriceBookEntry.IsActive = true;
            INSERT newPriceBookEntry;
            return newPriceBookEntry.Id;
        }catch(Exception ex){
            System.debug('Exception is::::'+ex.getMessage()+'--in line:::'+ex.getLineNumber());
            return null;
        }
    }
    public static Boolean addOrderItem(String order_id, String PriceBookEntryId,Decimal price,String orderPriceBookId ){
        try{
            //Add Order Item
            OrderItem ordItemobj = new OrderItem();
            ordItemobj.OrderId = order_id;
            ordItemObj.PricebookEntryId = PriceBookEntryId;
            ordItemObj.Price_Book__c = orderPriceBookId;
            ordItemObj.UnitPrice = price;
            ordItemObj.Quantity = 1;
            ordItemObj.Supplier_Unit_Price__c = price*(0.9);
            INSERT ordItemObj;
            return true;
        }catch(Exception ex){
            System.debug('Exception is::::'+ex.getMessage()+'--in line:::'+ex.getLineNumber());
            return false;
        }
    }
    public static Pricebook2 getStdPriceBook() {
        if (standardPriceBook == null) 
            standardPriceBook = [SELECT Id FROM Pricebook2 WHERE isStandard = true LIMIT 1];
        return standardPriceBook;    
    }
    public static ID getStdPricebookId() {
        if (Test.isRunningTest())
            return Test.getStandardPricebookId();
        return getStdPricebook().id;    
    } 
}