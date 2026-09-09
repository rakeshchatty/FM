@isTest
public class OrderTriggerHelperTest {

	public static Id parentRecordtype = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
	public static Id childRecordType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
	public static Id pricebookId = Test.getStandardPricebookId();

	@testSetup static void setup() {
		TestDataHelper.insertVat();

		TestDataHelper.insertSupplier('First Mile Ltd');

		Account parentAccount = new Account(Name='Parent Account', InvoiceFrequency__c='Per order', RecordTypeId=parentRecordtype);
		INSERT parentAccount;

		Account childAccount = new Account(Name='Child Account', InvoiceFrequency__c='Monthly', IsInvoiceFrequencyOverride__c = true, ParentId=parentAccount.Id, RecordTypeId=childRecordType, Enqix_Dead_Live__c = 'Live', Price_Book__c = Test.getStandardPricebookId());
		INSERT childAccount;

		List<Product2> lstProds = new List<Product2>();
		for (Integer i=0; i<3; i++) {
			lstProds.add(createTestProduct('Prod-' + (i+1), 10, (i+1)));
		}
		INSERT lstProds;

		List<PricebookEntry> lstStandardPrice = new List<PricebookEntry>();
		for (Integer i=0; i<3; i++) {
			lstStandardPrice.add(new PricebookEntry(
				Pricebook2Id = pricebookId,
				Product2Id = lstProds.get(i).Id,
				UnitPrice = 100,
				IsActive = true
			));
		}
		INSERT lstStandardPrice;

		Order Order1 = new Order(
			AccountId = childAccount.id,
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
		INSERT Order1;

		INSERT (new OrderItem(
			OrderId = Order1.Id,
			Quantity = 1,
			PriceBookEntryId = lstStandardPrice.get(1).Id,
			UnitPrice = 100
		));

		Order1.Status = 'Delivered';
		Test.startTest();
		UPDATE Order1;
		Test.stopTest();
	}

	private static testMethod void testReparenting() {
		// reparent location
		Account parentAccount2 = TestDataHelper.insertAccount();
		Contact financeContact = TestDataHelper.insertContact(parentAccount2.Id, 'Lastname');
		Account location = [SELECT Id FROM Account WHERE RecordTypeId = :childRecordType LIMIT 1];
		location.ParentId = parentAccount2.Id;
		UPDATE location;

		Order order2 = new Order(
			AccountId = location.id,
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
		INSERT order2;
		PricebookEntry pe = [SELECT Id FROM PricebookEntry LIMIT 1];
        Test.startTest();
		INSERT (new OrderItem(
			OrderId = order2.Id,
			Quantity = 1,
			PriceBookEntryId = pe.Id,
			UnitPrice = 100
		));

		order2.status = 'Delivered';
		
		UPDATE order2;
		Test.stopTest();
		System.assertEquals(2, [SELECT Id FROM Invoice_Header__c].size(), 'Expecting 2 invoices');
	}

	private static testMethod void testContinueInvoicing() {
		Account location = [SELECT Id FROM Account WHERE RecordTypeId = :childRecordType LIMIT 1];
		Order order2 = new Order(
			AccountId = location.id,
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
		INSERT order2;
		PricebookEntry pe = [SELECT Id FROM PricebookEntry LIMIT 1];
		INSERT (new OrderItem(
			OrderId = order2.Id,
			Quantity = 1,
			PriceBookEntryId = pe.Id,
			UnitPrice = 100
		));

		order2.status = 'Delivered';
		Test.startTest();
		UPDATE order2;
		Test.stopTest();
		System.assertEquals(1, [SELECT Id FROM Invoice_Header__c].size(), 'Expecting 1 invoices');
	}

	private static Product2 createTestProduct(String prodName, Integer recycleKG, Integer idx) {
		String rpGroup = (Math.mod(idx, 2) == 0)?'Cardboard':'Food Recycling';
		Product_Category__c proCat= new Product_Category__c(Name = 'Test');
		INSERT proCat;

		Product_Skin__c skin = new Product_Skin__c(Name = 'WEEE test');
		INSERT skin;

		Product2 prod = TestDataHelper.createProduct(prodName, '123', 'Delivery', proCat.Id);
		prod.Report_Groupings__c = rpGroup;
		prod.Recycle_KG__c = recycleKG;
		prod.Product_Skins__c = skin.Id;
		prod.Delivery_Category__c = 'Delivery';

		return prod;
	}
}