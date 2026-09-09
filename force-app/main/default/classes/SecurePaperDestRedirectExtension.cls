public with sharing class SecurePaperDestRedirectExtension {

	Id SPDId;

	public SecurePaperDestRedirectExtension(ApexPages.StandardController controller) {
		SPDId = controller.getId();
	}

	public PageReference redirect() {
		PageReference pdf = Page.SecurePaperDestPdf;
        pdf.getParameters().put('Id', SPDId);
		Blob file;
		if (Test.IsRunningTest()) file = Blob.valueOf('test blob');
        else file = pdf.getContentAsPdf();
        Compliance_Doc__c SPD = [select Name from Compliance_Doc__c where Id = :SPDId];
		List<ContentDocumentLink> cdlList = [select ContentDocumentId from ContentDocumentLink where LinkedEntityId = :SPDId and ContentDocument.Title = :SPD.Name];
		ContentVersion cv = new ContentVersion();
        cv.Title = SPD.Name;
        cv.VersionData = file;
		cv.PathOnClient = 'SPD.pdf';
		if (cdlList.size() > 0) cv.ContentDocumentId = cdlList[0].ContentDocumentId;
        insert cv;
		if (cdlList.size() > 0) return new PageReference('/apex/SecurePaperDestPdf?id='+SPDId);
		else {
			Id condoc = [select ContentDocumentId from ContentVersion where Id = :cv.Id].ContentDocumentId;
			ContentDocumentLink cdl = new ContentDocumentLink();
			cdl.ContentDocumentId = condoc;
			cdl.LinkedEntityId = SPDId;
			cdl.ShareType = 'I';
			insert cdl;
			return new PageReference('/apex/SecurePaperDestPdf?id='+SPDId); 
		}
	}
}