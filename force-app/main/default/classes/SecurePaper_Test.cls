@isTest
public with sharing class SecurePaper_Test {

	@testSetup static void setup() {
        // Create Product Skins
        Product_Skin__c secdestrPS = new Product_Skin__c(); 
        secdestrPS.Name = 'Sec Destr'; 
        insert secdestrPS;

        Product_Skin__c weee = new Product_Skin__c(); 
        weee.Name = 'WEEE'; 
        insert weee;
        
        TestDataHelper.insertSupplier('First Mile Ltd');
    }
    
    @future
    private static void insertCustomSetting(){
      Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
      system.debug('DEBUG========================='+testRecord);
	  insert testRecord;
	}
	
	@isTest
	public static void createTest(){
        Test.StartTest();
        insertCustomSetting();
        Test.stopTest();
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
		system.debug('Começando testes Secure Destructions');
        //Products
        List<Product2> lstProds = new List<Product2>();
  

        system.debug('Criar Produtos SKIN:: ');
        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProductSkin('Prod-' + (i+1), 100, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
         
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
          
        for (Integer i=0; i<11; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 0,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        
        //Insert Parent Accounts
        Account parentAccount = TestDataHelper.insertAccount();
        Account locationAccount = TestDataHelper.insertLocation(parentAccount.Id,null);

        String Enqix_Id = '9999990';

        //Insert Orders for Per Order
        Order ord1 = new Order(
            AccountId = locationAccount.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Enqix_Id__c = Enqix_Id,
            POD_Delivery_Date__c = system.today(),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId
        );
        insert ord1;

        Attachment orderAttachement = new Attachment(
            Name = 'POD_'+Enqix_Id+'.jpg',
            ParentId = ord1.Id,
            Body = EncodingUtil.base64Decode('Testinho')
        ); 
        insert orderAttachement;

        List <ContentVersion> cvList = new List <ContentVersion>();
        ContentVersion cv = new ContentVersion();
        cv.Title = 'test cdoc';
        cv.VersionData = blob.valueOf('test data.pdf');
        cv.PathOnClient = 'test.pdf';
        cvList.add(cv);
        insert cvList;

        Id cdId = [select ContentDocumentId from ContentVersion where title = 'test cdoc' limit 1].ContentDocumentId;

        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 100,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 0,
            Detrack_QRCode__c = 'Test detrackCode',
            Product2Id = lstProds[0].Id
        ));
        insert lstOLI;

        ord1.Status = 'Delivered';
        system.debug('ORDEM DELIVERED COM SKIN SECURE DESTRUCTION NO PRODUCT SKIN');
        upsert ord1;

		Set<Id> orderIds = new Set<Id>();
        orderIds.add(ord1.Id);

        Compliance_Doc__c sd = new Compliance_Doc__c();
        sd.Account__c = locationAccount.Id;
        sd.Order__c = ord1.Id;
        sd.RecordTypeId = Schema.SObjectType.Compliance_Doc__c.getRecordTypeInfosByName().get('Waste Transfer Notes').getRecordTypeId();
        sd.Status__c = 'Draft';
        insert sd;
        
        


        List<Compliance_Doc__c> comps = [SELECT Id, 	Order__c
                                        FROM Compliance_Doc__c 
                                          WHERE Order__c in :orderIds];

		for(Compliance_Doc__c c : comps){
			ApexPages.StandardController sc = new ApexPages.StandardController(c);
            SecurePaperDestRedirectExtension idre = new SecurePaperDestRedirectExtension(sc);
			SecurePaperDestExtension noe = new SecurePaperDestExtension(sc);
			PageReference p = idre.redirect();
            
        }

	}

	private static Product2 createTestProductSkin(String prodName, Integer recycleKG, Integer idx) {
        //system.debug('Entrei no create test product SKIN');
        //List <Product_Skin__c> n =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE 'SECURE DESTRUCTION'];
        //system.debug('TAMANHO DA LISTA DE PRODUCT SKINS COM SECURE DESTRUCTION NO NOME '+n.size());
        //a3A4E0000006ue1UAA (id) Já existe com este nome 
        //Product_Skin__c n = new Product_Skin__c(); 
        //n.Name = 'Sec Destr'; 
        //insert n;
        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
		insert proCat;
		
        Product_Skin__c ps = new Product_Skin__c(
        Name = 'Sec Destr - Tag Prefix: CDD - Weight KG: 25'
        );
        insert ps;
        Product_Skin__c ps1 = new Product_Skin__c(
        Name = 'Sec Destr - Tag Prefix: SD - Weight KG: 25'
        );
        insert ps1;
        Product_Skin__c ps2 = new Product_Skin__c(
        Name = 'Sec Destr - Tag Prefix: Exchange - Weight KG: 25'
        );
        insert ps2;
        //List <Product_Skin__c> product_skins =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE '%Sec Destr%'];
        List <Product_Skin__c> product_skins =[SELECT Id, Name FROM  Product_Skin__c WHERE Name = 'Sec Destr - Tag Prefix: CDD - Weight KG: 25'];
        //system.debug('Existem ' + product_skins.size() + ' Product Skins com Sec Destr no nome'); 
        //Product_Skin__c product_skin = product_skins.get(0);

        //system.debug('SKIN:: '+n.get(0)+'Name::::'+n.get(0).Name);
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', procat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
		prod.Product_Skins__c = product_skins[0].Id;
        
		return prod;
       /* Product2 prod = new Product2(
            Name = prodName,  
            Product_Type__c = 'Delivery',
            Report_Groupings__c = rpGroup,
            Recycle_KG__c = recycleKG,
            //Product_Skins__c = 'a3A4E000000BZrpUAG', ERROR - IDs must never be written as hardcoded, always use query and assign!
            Product_Skins__c = product_skins[0].Id,
            IsActive = true,
            Product_Category__c = proCat.Id,
			UnitCost__c = 10,
            ProductCode = '123',
            Nl_accode__c = '4001'
        );        
        //prod.Product_Skins__c = n.Id;
        //system.debug('SAI do create test product SKIN');
        return prod;*/
    }
}