@isTest
public class MapsRouteProductsControllerTest {

	@isTest
	static void setup(){
		Account parentAccount = TestDataHelper.createAccount();
		INSERT parentAccount;
		//Account setup
		Account novaConta = new Account(
			Name = 'test location',
			ParentId = parentAccount.Id,
			RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId(),
			Price_Book__c = Test.getStandardPricebookId(),
			Enqix_Dead_Live__c = 'Live'
		);
		insert novaConta;


		//Product setup

		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');

		Product_Category__c pc = new Product_Category__c();
		pc.Name = 'test pc';
		pc.Enqix_Id__c = 12345;
		pc.product_category_key__c = 'test pck';
		insert pc;

		Waste_Category__c wc = new Waste_Category__c();
		wc.Name = 'Cardboard Waste';
		wc.Codes__c = '12345';
		insert wc;

		Container_Type__c ct = new Container_Type__c();
		ct.Name = 'Not Sack';
		ct.Type__c = 'Bag';
		insert ct;

		Product2 prod = TestDataHelper.createProduct('test prod Recycling Sack', '12355321', 'Collection', pc.Id, null, null,'265');
		INSERT prod;

		//Order Setup
		Order newOrd = new Order(
			AccountId = novaConta.Id,
			EffectiveDate = System.today(),
			Delivery_Date__c = System.today(),
			Status = 'Confirmed',
			AD_KG__c = 100,
			Recycled_KG__c = 100,
			WTE_KG__c = 100,
			Tonnes_CO2_Saved__c = 100,
			Pricebook2Id = Test.getStandardPricebookId()
		);
		insert newOrd;

		Id pricebookId = Test.getStandardPricebookId();

		List < PricebookEntry > lstStandardPrice = new List < PricebookEntry > ();

		for (Integer i = 0; i < 1; i++) {
			lstStandardPrice.add(new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = prod.Id,
				UnitPrice = 100,
				IsActive = true
			));
		}
		insert lstStandardPrice;

		OrderItem oi = new OrderItem(
			OrderID=newOrd.Id,
			Quantity = 2,
			PriceBookEntryId = lstStandardPrice.get(0).Id,
			UnitPrice = 100,
			Supplier__c = supplier.Id
		);
		insert oi;

		system.debug('Order criada --> '+newOrd);

		//SF maps setup
		maps__Route__c mapRoute = new maps__Route__c();
		mapRoute.Name = 'Test Route';
		mapRoute.IsComplete__c = true;
		mapRoute.maps__Date__c = system.TODAY();
		insert mapRoute;

		maps__Waypoint__c mapWaypoint = new maps__Waypoint__c();
		mapWaypoint.Name = 'Test Waypoint';
		mapWaypoint.Order__c = newOrd.Id;
		mapWaypoint.maps__Account__c = novaConta.ID;
		mapWaypoint.maps__Route__c = mapRoute.Id;
		mapWaypoint.maps__LinkId__c = String.valueOf(newOrd.Id);
		insert mapWaypoint;

		newOrd.Maps_Route__c = mapRoute.Id;

		system.debug('waypoint Order --> '+mapWaypoint.Order__c);
		system.debug('WayPoint ID --> '+mapWaypoint.Id);

		//Start test
		test.startTest();
		PageReference pageRef = Page.MapsRouteProducts;
		Test.setCurrentPage(pageref);
		MapsRouteProductsController controller = new MapsRouteProductsController(new ApexPages.StandardController(mapRoute));
		test.stopTest();
	}
}