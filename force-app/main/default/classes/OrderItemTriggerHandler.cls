public class OrderItemTriggerHandler {

	public static void handleTrigger(List<OrderItem> newList, Map<Id, OrderItem> oldMap, TriggerOperation operation) {
		switch on operation {
			when BEFORE_DELETE {
				OrderProduct.preventDeletion(oldMap.values());
			}
		}
	}
}