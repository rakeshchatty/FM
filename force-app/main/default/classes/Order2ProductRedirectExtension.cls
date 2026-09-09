public with sharing class Order2ProductRedirectExtension {
    
    Id OrderId;
    
    // we are extending the OpportunityLineItem controller, so we query to get the parent OpportunityId
    public Order2ProductRedirectExtension (ApexPages.StandardController controller) {
        OrderId = [select Id, OrderId from OrderItem where Id = :controller.getRecord().Id limit 1].OrderId ;
       
    }
    // then we redirect to our desired page with the Opportunity Id in the URL
    
    public pageReference redirect(){
        
        return new PageReference('/apex/Order2ProductEntry?id=' + OrderId);
    }
    
}