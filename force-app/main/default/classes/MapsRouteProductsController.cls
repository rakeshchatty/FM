public class MapsRouteProductsController {
    public maps__Route__c Route;
    public List <OrderItem> OrderItems;
    
    public list<OrderWrapper> OrdersWrap {get; set;}
    
    public MapsRouteProductsController(ApexPages.StandardController controller) {
        Route = (maps__Route__c)controller.getRecord();
        
        OrderItems = new list<OrderItem>();
        list<Id> OrderIds = new list<Id>();
        
        list<maps__Waypoint__c> RouteWayPoints = [Select Id, Order__c, maps__BaseObject__c From maps__Waypoint__c where maps__Route__c = :Route.Id];
        map<string, Integer> OrderVsWayPoint = new map<string, integer>();
        system.debug('WayPoint --> '+RouteWayPoints);
        
        for(maps__Waypoint__c WayPoint : RouteWayPoints){
            OrderIds.add(WayPoint.Order__c);
            system.debug('Order --> '+ WayPoint.Order__c);
            
            if(OrderVsWayPoint.containsKey(WayPoint.Order__c)){
                integer totalCount = OrderVsWayPoint.get(WayPoint.Order__c);
                totalCount = totalCount +1;
                OrderVsWayPoint.put(WayPoint.Order__c, totalCount);
            }else{
                OrderVsWayPoint.put(WayPoint.Order__c, 1);
            }
        }
        
        system.debug(OrderIds);
        OrderItems = [Select Id, OrderId, Product2Id, Product2.Name, Quantity from OrderItem where OrderId IN :OrderIds];
        
        map<Id, String> ProductMap = new map<Id, String>();
        map<Id, Integer> ProductAndQuantity = new map<Id, Integer>();
        
        for(OrderItem oi : OrderItems){
            for(integer i=0; i<OrderVsWayPoint.get(oi.OrderId); i++){
                If(ProductAndQuantity.containsKey(oi.Product2Id)){
                    integer totalQuantity = ProductAndQuantity.get(oi.Product2Id);
                    totalQuantity  = totalQuantity + integer.valueOf(oi.Quantity);
                    ProductAndQuantity.put(oi.Product2Id, totalQuantity);
                }else{
                    ProductAndQuantity.put(oi.Product2Id, integer.valueOf(oi.Quantity));
                }
            }
            ProductMap.put(oi.Product2Id, oi.Product2.Name);
        }
        
        OrdersWrap  = new list<OrderWrapper>();
        for(Id productId : ProductAndQuantity.keySet()){
            OrderWrapper ord = new OrderWrapper(ProductMap.get(productId), ProductAndQuantity.get(productId));
            OrdersWrap.add(ord);
        }
    }
    
    
    public class OrderWrapper{
        public string ProductName {get; set;}
        public integer Quantity {get; set;}
        
        
        public OrderWrapper(String PrdName, Integer Qty){
            ProductName = PrdName;
            Quantity = qty;
        }
        
    }
}