@isTest
public class WasteTransferNoteRedirectExtensionTest {

	@isTest
	static void redirect() {
		Account parentAccount = TestDataHelper.createAccount();
		parentAccount.Name = 'First Mile';
		INSERT parentAccount;
		Account childAccount = TestDataHelper.createLocation(parentAccount.Id, null);
		INSERT childAccount;

		Contact contact = TestDataHelper.insertContact(parentAccount.Id, 'FM');
		TestDataHelper.insertAccountContactRelation(childAccount.Id, contact.Id, 'Service Contact;Finance Contact');

		Order order = TestDataHelper.insertOrder(childAccount.Id);
		Attachment attachment = new Attachment(ParentId = order.Id, Name = 'POD_'+order.Enqix_Id__c+'.jpg', Body = Blob.valueOf('Test Data'));
		INSERT attachment;

		ContentVersion contentVersion = new ContentVersion(Title = 'POD_image_', VersionData = Blob.valueOf('test'), PathOnClient = 'POD_image_');
		INSERT contentVersion;
		Id ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :contentVersion.Id LIMIT 1].ContentDocumentId;
		ContentDocumentLink contentDocumentLink = new ContentDocumentLink(ContentDocumentId = contentDocumentId, LinkedEntityId = order.Id, ShareType = 'I');
		INSERT contentDocumentLink;

		Suppliers__c supp = new Suppliers__c();
		supp.Name = 'First Mile Ltd';
		supp.Phone_Number__c = '123456789';
		INSERT supp;

		Compliance_Doc__c cdoc = new Compliance_Doc__c();
		cdoc.RecordTypeId = Schema.SObjectType.Compliance_Doc__c.getRecordTypeInfosByName().get('Waste Transfer Notes').getRecordTypeId();
		cdoc.Name = 'test cdoc';
		cdoc.Account__c = childAccount.Id;
		cdoc.Contractor__c = supp.Id;
		cdoc.StartDate__c = system.today();
		cdoc.EndDate__c = System.today() + 10;
		INSERT cdoc;

		new WasteTransferNoteRedirectExtension(new ApexPages.StandardController(cdoc)).redirect();
		new WasteTransferNoteExtension(new ApexPages.StandardController(cdoc));
	}
}