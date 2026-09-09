/** 
(c) 2018 Nexell GmbH / Rolling-Space
Developed by Nexell GmbH, Zug (Switzerland) / Rolling-Space, Braga (Portugal)
@date Date of creation mm.yyyy 
@author Name of initial developer 

@description Initial PT or Case number + description of what the class does 

@modifications dd.mm.yyyy [XX] PT or Case number followed by short description of change 
Example: 02.04.2018 [PC] PT5703 - Added support of new Account fields 
*/
@isTest
private class TestConsignment {
	
	@testSetup static void setup() {
        // Create Product Skins
        Product_Skin__c secdestrPS = new Product_Skin__c(); 
        secdestrPS.Name = 'Sec Destr'; 
        insert secdestrPS;

        Product_Skin__c weee = new Product_Skin__c(); 
        weee.Name = 'WEEE'; 
        insert weee;
    }
	
    public static testmethod void SecureDestructions(){
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
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        
        
        //Insert Parent Accounts
        Account parent = TestDataHelper.insertAccount();
        Account parentPerOrder = TestDataHelper.insertLocation(parent.Id, null);

        //Insert Orders for Per Order
        Order ord1 = new Order(
            AccountId = parentPerOrder.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        insert ord1;

        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 0
        ));
        insert lstOLI;

        ord1.Status = 'Delivered';
        system.debug('ORDEM DELIVERED COM SKIN SECURE DESTRUCTION NO PRODUCT SKIN');
        upsert ord1;


}

    public static testmethod void ConsignmentNotes(){
        system.debug('Começando testes Consignment Notes');
        //Products
        List<Product2> lstProds = new List<Product2>();
        
        system.debug('Criar Produtos SKIN:: ');
        for (Integer i=0; i<11; i++) {
            lstProds.add(createTestProductSkinNote('Prod-' + (i+1), 100, (i+1)));
        }
        insert lstProds;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
        
        for (Integer i=0; i<11; i++) {
            lstStandardPrice.add(new PricebookEntry(
                Pricebook2Id = pricebookId,
                Product2Id = lstProds.get(i).Id,
                UnitPrice = 100,
                IsActive = true
            ));
        }
        insert lstStandardPrice;
        Account parent = TestDataHelper.insertAccount();
        Account parentPerOrder = TestDataHelper.insertLocation(parent.Id, null);

        //Insert Orders for parentPerOrder
        Order ord1 = new Order(
            AccountId = parentPerOrder.id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100,
            Pricebook2Id = pricebookId,
            Is_Salesforce__c = true
        );
        insert ord1;

        //order Items
        List<OrderItem> lstOLI = new List<OrderItem>();
        lstOLI.add(new OrderItem(
            OrderId = ord1.Id,
            Quantity = 1,
            PriceBookEntryId = lstStandardPrice.get(1).Id,
            UnitPrice = 0
        ));
        insert lstOLI;
        system.debug(lstOLI);

        ord1.Status = 'Delivered';
        system.debug('ORDEM DELIVERED COM SKIN SECURE DESTRUCTION NO PRODUCT SKIN');
        upsert ord1;



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

        List <Product_Skin__c> product_skins =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE '%Sec Destr%'];
        system.debug('Existem ' + product_skins.size() + ' Product Skins com Sec Destr no nome'); 
        Product_Skin__c product_skin = product_skins.get(0); 

        //system.debug('SKIN:: '+n.get(0)+'Name::::'+n.get(0).Name);
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
        prod.Product_Skins__c = product_skin.Id;
     
        return prod;
    }

     private static Product2 createTestProductSkinNote(String prodName, Integer recycleKG, Integer idx) {
        //system.debug('Entrei no create test product SKIN');
        //List <Product_Skin__c> n =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE 'SECURE DESTRUCTION'];
        //system.debug('TAMANHO DA LISTA DE PRODUCT SKINS COM SECURE DESTRUCTION NO NOME '+n.size());
        //a3A4E0000006ue1UAA (id) Já existe com este nome 
        //Product_Skin__c n = new Product_Skin__c(); 
        //n.Name = 'Sec Destr'; 
        //insert n;

        Product_Category__c proCat= new Product_Category__c(Name = 'Test');
		insert proCat;

        List <Product_Skin__c> product_skins =[SELECT Id, Name FROM  Product_Skin__c WHERE Name LIKE '%WEEE%' OR Name LIKE '%Batteries%'];
        system.debug('Existem ' + product_skins.size() + ' Product Skins com WEEE no nome'); 
        Product_Skin__c product_skin = product_skins.get(0);

        //system.debug('SKIN:: '+n.get(0)+'Name::::'+n.get(0).Name);
        String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
        
        Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
        prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
        prod.Product_Skins__c = product_skin.Id;
     
        return prod;
    }
}