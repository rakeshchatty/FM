public class ContentDocumentLinkHandler {

	public static void insertAttachment(List<ContentDocumentLink> contentDocumentLinks){
		Set<Id> orderIds = new Set<Id>();
		for (ContentDocumentLink cdl : contentDocumentLinks) {
			if (IdUtil.isOrder(cdl.LinkedEntityId)) {
				orderIds.add(cdl.LinkedEntityId);
			}
		}

		if (!orderIds.isEmpty()) {
			OrderItemTriggerNotificationHandler.sendNotification(orderIds);
		}
	}

	public static void deleteAttachment(List<ContentDocument> contentDocuments) {
		Set<Id> contentDocumentIds = new Set<Id>();
		for (ContentDocument contentDocument : contentDocuments){
			contentDocumentIds.add(contentDocument.Id);
		}
		
		Set<Id> orderIds = new Set<Id>();
		List<ContentDocumentLink> contentDocumentLinks = [SELECT LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId IN :contentDocumentIds LIMIT 10000];
		for (ContentDocumentLink cdl : contentDocumentLinks) {
			if (IdUtil.isOrder(cdl.LinkedEntityId)) {
				orderIds.add(cdl.LinkedEntityId);
			}
		}

		if (!orderIds.isEmpty()) {
			OrderItemTriggerNotificationHandler.sendNotification(orderIds);
		}
	}
}