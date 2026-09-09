public class OrderNotificationController {
    
    public static Boolean sendNotificationFlag = true;
    /////////////////// Added by ankit ////
    @future(callout=true)
    public static void sendNotification(string orderId,string supplierId)
    {
        string endpointURL=label.OrderNotifiactionURL;
        HttpRequest req = new HttpRequest();
        endpointURL=endpointURL.replace('ORDER_ID',orderId).replace('SUPPLIER_ID',supplierId);
        system.debug('endpointURL--'+endpointURL);
        req.setEndpoint(endpointURL);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json;charset=UTF-8');
        
        
        
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug(res.getBody());
    }
}