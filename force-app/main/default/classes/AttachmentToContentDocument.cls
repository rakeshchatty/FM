public without sharing class AttachmentToContentDocument {

	private Input[] inputs;

	public class Input {
		@InvocableVariable(required=true label='Attachment Ids')
		public List<Id> attachmentIds;
		@InvocableVariable(required=true label='Parent Id')
		public Id parentId;
	}

	@InvocableMethod(label='Attachment to Content Document')
	public static void convert(Input[] inputs) {
		List<ContentVersion> contentVersions = new List<ContentVersion>();

		for (Input input : inputs) {
			for (Attachment attachment : [SELECT Name, Body FROM Attachment WHERE Id IN :input.attachmentIds AND BodyLength > 0]) {
				contentVersions.add(new ContentVersion(Title = attachment.Name, PathOnClient = attachment.Name, VersionData = attachment.Body, FirstPublishLocationId = input.parentId));
			}
		}

		if (contentVersions != null) {
			INSERT contentVersions;
		}
	}
}