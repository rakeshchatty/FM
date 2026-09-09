trigger ContentDocumentTrigger on ContentDocument (before delete) {

	ContentDocumentLinkHandler.deleteAttachment(Trigger.old);
}