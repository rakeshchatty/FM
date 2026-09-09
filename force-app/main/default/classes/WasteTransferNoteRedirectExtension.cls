public with sharing class WasteTransferNoteRedirectExtension {

	Id wtnId;

	public WasteTransferNoteRedirectExtension(ApexPages.StandardController controller) {
		wtnId = controller.getId();
	}

	public PageReference redirect() {
		PageReference pdf = Page.WasteTransferNotePdf;
		pdf.getParameters().put('Id', wtnId);

		Blob file = Test.IsRunningTest() ? Blob.valueOf('test blob') : pdf.getContentAsPdf();
		String wtnName = [SELECT Name FROM Compliance_Doc__c WHERE Id = :wtnId].Name;
		ContentVersion cv = new ContentVersion(Title = wtnName, VersionData = file, PathOnClient = 'WTN.pdf');
		List<ContentDocumentLink> cdlList = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :wtnId AND ContentDocument.Title = :wtnName];
		if (!cdlList.isEmpty()) {
			cv.ContentDocumentId = cdlList[0].ContentDocumentId;
		}
		INSERT cv;

		if (cdlList.isEmpty()) {
			Id condocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id].ContentDocumentId;
			ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = condocId, LinkedEntityId = wtnId, ShareType = 'I');
			INSERT cdl;
		}
		return new PageReference('/sfc/servlet.shepherd/version/download/'+cv.Id);
	}
}