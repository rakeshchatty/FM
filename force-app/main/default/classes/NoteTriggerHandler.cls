public class NoteTriggerHandler {

	public static void afterInsertOrDeleteEvent(List<Note> notes) {
		Set<Id> orderIds = new Set<Id>();
		for (Note note : notes) {
			if (IdUtil.isOrder(note.parentId)) {
				orderIds.add(note.ParentId);
			}
		}

		if (!orderIds.isEmpty()) {
			OrderItemTriggerNotificationHandler.sendNotification(orderIds);
		}
	}
}