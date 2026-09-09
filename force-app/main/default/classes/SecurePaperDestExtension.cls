public with sharing class SecurePaperDestExtension {

	public string recordId {get; set;}
	public Compliance_Doc__c spd {get; set;}
	public string url {get; private set;}
    public Attachment atts {get; private set;}
    public List<ContentVersion> cvLista {get; private set;}
    public Integer quantity {get; private set;}

    public List<OrderItem> tagNumbers {get; private set;}
	
	public SecurePaperDestExtension(ApexPages.StandardController ctrl) {
		recordId = ctrl.getId();
		spd = [select Account__r.Name, Order__c, Order__r.Enqix_Id__c, Order__r.ShippingStreet, Order__r.ShippingState, Order__r.ShippingPostalCode, 
				Order__r.ShippingCountry, Order__r.ShippingCity, Order__r.POD_Delivery_Date__c, Order__r.OrderNumber, Order__r.Delivery_Signature_Name__c 
				from Compliance_Doc__c where Id = :recordId];
		getSignature();
        getTagNumbers();
	}

	private void getSignature() {
        if (spd.Order__c != null) {
            try {


                string title = '%POD_image_'+ spd.Order__r.Enqix_Id__c+'%';
                List<ContentDocumentLink> cdlLista = [select Id, ContentDocumentId from ContentDocumentLink where LinkedEntityId = :spd.Order__c and ContentDocument.Title LIKE :title limit 1];
                if(cdlLista.size()!=0){
                    cvLista = [select Id from ContentVersion where ContentDocumentId = :cdlLista.get(0).ContentDocumentId AND IsLatest = true limit 1];
                    system.debug(cvLista);
                    if (cvLista.size() != 0) {
                        ContentVersion cv = cvLista.get(0);
                        url = '/sfc/servlet.shepherd/version/download/' + cv.Id;
                    }
                }
                

                if (String.isBlank(url)) {
                    title = 'POD_'+spd.Order__r.Enqix_Id__c+'.jpg';
                    atts = [select Id, Name, Description from Attachment where ParentId = :spd.Order__c and Name = :title limit 1];
                    url = '/servlet/servlet.FileDownload?file='+atts.Id;
                }
            }
            catch (Exception e) {
                system.debug(e.getMessage());
            }
        }
    }

    private void getTagNumbers() {
        List <Product_Skin__c> productSkin1 = [Select id, Name from Product_Skin__c where Name = 'Sec Destr - Tag Prefix: CDD - Weight KG: 25'];
        List <Product_Skin__c> productSkin2 = [Select id, Name from Product_Skin__c where Name = 'Sec Destr - Tag Prefix: SD - Weight KG: 25'];
        List <Product_Skin__c> productSkin3 = [Select id, Name from Product_Skin__c where Name = 'Sec Destr - Tag Prefix: Exchange - Weight KG: 25'];
        tagNumbers = [select Detrack_QRCode__c, Quantity, Product2.Product_Skins__c from OrderItem where (OrderId = :spd.Order__c AND Product2.Product_Skins__c = :productSkin1[0].id) OR (OrderId = :spd.Order__c AND Product2.Product_Skins__c= :productSkin2[0].id) OR (OrderId = :spd.Order__c AND Product2.Product_Skins__c= :productSkin3[0].id)];
        quantity = 0;
        for (OrderItem oi : tagNumbers) {
            quantity += Integer.valueOf(oi.Quantity);
        }
    }
}