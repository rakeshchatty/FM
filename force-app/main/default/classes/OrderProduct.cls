public class OrderProduct {

	public static void preventDeletion(List<OrderItem> deletedItems) {
		if (FeatureManagement.checkPermission('DeleteItemFromOrder')) {
			return;
		}

		for (OrderItem orderItem : deletedItems) {
			orderItem.addError(Label.NoPermissionToDeleteOrderItem);
		}
	}
}