public class AttachmentHandler {

	public static void afterInsertOrDeleteEvent(List<Attachment> attachments){
		Set<Id> orderIds = new Set<Id>();
		for (Attachment attachment : attachments) {
			if (IdUtil.isOrder(attachment.parentId)) {
				orderIds.add(attachment.ParentId);
			}
		}

		if (!orderIds.isEmpty()) {
			OrderItemTriggerNotificationHandler.sendNotification(orderIds);
		}
	}
}