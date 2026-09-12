@isTest
private class AttachmentToContentDocumentTest {

	@isTest
	static void test() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Case testCase = new Case(Type = 'Operations', Subject = 'Miley PR: Broken Bin', Location__c = location.Id);
		INSERT testCase;

		Attachment attachment = new Attachment();
        attachment.ParentId = testCase.Id;
		attachment.Name = 'Test Attachment for Case';
		attachment.Body = Blob.valueOf('Test Data');
		INSERT attachment;

		AttachmentToContentDocument.Input input = new AttachmentToContentDocument.Input();
		input.attachmentIds = new List<Id>{attachment.Id};
		input.parentId = testCase.Id;

		Assert.areEqual(0, [SELECT Id FROM ContentVersion WHERE FirstPublishLocationId = :testCase.Id].size());

		Test.startTest();
		AttachmentToContentDocument.convert(new List<AttachmentToContentDocument.Input>{input});
		Test.stopTest();

		Assert.areEqual(1, [SELECT Id FROM ContentVersion WHERE FirstPublishLocationId = :testCase.Id].size());
	}
}