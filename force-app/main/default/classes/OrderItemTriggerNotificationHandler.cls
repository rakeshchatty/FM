public class OrderItemTriggerNotificationHandler {

	private static final String ENDPOINT = Label.OrderNotifiactionURL;

	public static void sendNotification(Set<Id> orderIds) {
		List<Order> orders = [SELECT Supplier__c FROM Order WHERE Id IN :orderIds AND Supplier__c != null AND Supplier_Status__c IN ('Quote Required', 'Accepted by FM', 'Confirmed', 'Unconfirmed') LIMIT 100];
		Map<Id, Id> orderToSupplierMap = new Map<Id, Id>();
		for (Order order : orders) {
			orderToSupplierMap.put(order.Id, order.Supplier__c);
		}

		if (!orders.isEmpty()) {
			try {
				sendNotification(orderToSupplierMap);
			} catch (Exception e) {
				System.debug(e);
			}
		}
	}

    @future(callout=true)
    private static void sendNotification(Map<Id, Id> orderToSupplierMap) {
        for (Id orderId : orderToSupplierMap.keySet()) {
            String endpointURL = ENDPOINT.replace('ORDER_ID', orderId).replace('SUPPLIER_ID', orderToSupplierMap.get(orderId)).replace('SUPPLIER_STATUS', 'Updated');
            HttpRequest req = new HttpRequest();
            req.setEndpoint(endpointURL);
            req.setMethod('GET');
            req.setHeader('Content-Type', 'application/json;charset=UTF-8');
            new Http().send(req);
        }
    }    	
}