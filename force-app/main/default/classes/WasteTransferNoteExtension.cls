public class WasteTransferNoteExtension {

	string recordId {get; set;}
	public Compliance_Doc__c cdoc {get; set;}
	public String url {get; set;}
	public string startdate {get; set;}
	public AccountContactRelation serviceContact {get; private set;}
	public Suppliers__c contractor {get; set;}
	public List<WTN_Waste_Category__c> wasteCategories {get; private set;}
	public String firstMileRegNumber {get; set;}

	public WasteTransferNoteExtension(ApexPages.StandardController ctrl) {
		recordId = ctrl.getId();
		cdoc = [select Order__c, Order__r.Enqix_Id__c, StartDate__c, Account__r.Parent.BillingPostalCode, Account__c, Account__r.Parent.Business_Registration_Number__c, Account__r.Parent.Billing_Address__c, Account__r.Parent.Name, Account__r.Parent.Enqix_Classification__c, Contractor__r.CarrierRegNo__c, Contractor__r.Name, WTN_Date_of_Transfer__c from Compliance_Doc__c where Id = :recordId];
		system.debug(cdoc.Contractor__r.Name);
		system.debug(cdoc);
		if (cdoc.Contractor__r.Name != 'First Mile') {
			firstMileRegNumber = [SELECT Business_Registration_Number__c FROM Account WHERE RecordType.Name = 'Account' AND Name = 'First Mile' AND Enqix_Dead_Live__c = 'Live'].Business_Registration_Number__c;
		}
		system.debug(cdoc.Account__r.Parent.Billing_Address__c);
		system.debug(cdoc.Account__r.Parent.Enqix_Classification__c);
		system.debug(cdoc.Account__r.Parent.Billing_Address__c);
		wasteCategories = [select Id, Waste_Category__r.Name, Waste_Category__r.Codes__c from WTN_Waste_Category__c where WTN__c = :recordId];
		getServiceContact();
		getStartDate();
		getSignature();

	}

	public void getServiceContact() {
		List < AccountContactRelation > acrs = [select Contact.Name, Roles from AccountContactRelation where AccountId =: cdoc.Account__c];
		for (AccountContactRelation acr: acrs) {
			List < string > roles = new list < string > ();
			roles.addAll(acr.Roles.split(';'));
			if (roles.size() > 1) {
				for (integer i = 0; i < roles.size(); i++) {
					if (roles[i] == 'Service Contact') {
						serviceContact = acr;
						break;
					}
				}
			} else {
				if (acr.Roles == 'Service Contact') {
					serviceContact = acr;
					break;
				}
			}
		}
		if (serviceContact == null) serviceContact = new AccountContactRelation();
	}

	public void getStartDate() {
		if (cdoc.StartDate__c != null) {
			string day = string.valueOf(cdoc.StartDate__c.day());
			string month = string.valueOf(cdoc.StartDate__c.month());
			string year = string.valueOf(cdoc.StartDate__c.year()).substring(2);
			startdate = day+'/'+month+'/'+year;
		}
		else startdate = '';
	}

	public void getSignature() {
		Map<Id,Order> orderMap = new Map<Id,Order>([select Id, Enqix_Id__c, (select Id, Name from Attachments) from Order where AccountId = :cdoc.Account__c order by CreatedDate desc]);
		//Set<Id> newSet = orderMap.keySet();
		List<Id> newList = new List<Id>(orderMap.keySet());
		system.debug(newList);
		for (Order ord : orderMap.values()) {
			if (ord.Attachments.size() > 0) {
				string title = 'POD_'+ord.Enqix_Id__c+'.jpg';
				for (Attachment a : ord.Attachments) {
					system.debug(a);
					if (a.Name.contains(title)) {
						url = '/servlet/servlet.FileDownload?file='+a.Id;
						break;
					}
				}
			}
		}
		if (String.isBlank(url) && newList.size() > 0) {
			string title = '%POD_image_%';
			List<ContentDocumentLink> cdl = [select Id, ContentDocumentId from ContentDocumentLink where LinkedEntityId IN :newList and ContentDocument.Title LIKE :title limit 1];
			if (cdl.size() > 0) {
				ContentVersion cv = [select Id from ContentVersion where ContentDocumentId = :cdl[0].ContentDocumentId AND IsLatest = true limit 1];
				system.debug(cv);
				url = '/sfc/servlet.shepherd/version/download/' + cv.Id;
				system.debug(url);
			}
		}
	}
}