trigger ContentDocumentLinkTrigger on ContentDocumentLink (after insert) {

	ContentDocumentLinkHandler.insertAttachment(Trigger.new);
}