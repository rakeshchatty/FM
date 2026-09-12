public class OrderItemTriggerHandler {

	public static void handleTrigger(List<OrderItem> newList, Map<Id, OrderItem> oldMap, TriggerOperation operation) {
		switch on operation {
			when BEFORE_DELETE {
				OrderProduct.preventDeletion(oldMap.values());
				new OrderItemTriggerHelper().subtractQuantityOrdered(oldMap);
			}
			when AFTER_DELETE {
				Vat.calculate(IdUtil.extractId(oldMap.values(), 'OrderId'));
			}
			when AFTER_INSERT, AFTER_UPDATE {
				Vat.calculate(IdUtil.extractId(newList, 'OrderId'));
			}
		}
	}
}