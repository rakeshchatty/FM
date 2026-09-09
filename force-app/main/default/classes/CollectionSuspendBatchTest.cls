@isTest
public class CollectionSuspendBatchTest {
	static testMethod void testMethod1() {
		Account parentAccount = TestDataHelper.createAccount();
		INSERT parentAccount;
		Account locationAccount = TestDataHelper.createLocation(parentAccount.Id, Null);
		INSERT locationAccount;

		Product_Category__c pc = new Product_Category__c();
		pc.Name = 'test';
		pc.Enqix_Id__c = 1;
		pc.Product_Category_Key__c = 'test';
		INSERT pc;

		product2 prod = TestDataHelper.insertProduct('Product 1', '123', 'Collection', pc.id);

		Suppliers__c s = new Suppliers__c();
		s.Name = 'First Mile Ltd';
		s.Enqix_ID__c = 23;
		s.Phone_Number__c = '123423';
		INSERT s;

		Supplier_Product__c sp = new Supplier_Product__c();
		sp.Name = 'test';
		sp.Product__c = prod.id;
		sp.Enqix_UID__c = 'test';
		sp.Enqix_Pk__c = 1;
		sp.Supplier__c = s.id;
		INSERT sp;

		Schedule__c sc = new Schedule__c();
		sc.Collection_Note__c = 'Collection Note';
		sc.Days__c = 'Monday';
		sc.Location__c = locationAccount.Id;
		sc.Price_Book__c = Test.getStandardPricebookId();
		sc.Product__c = prod.Id;
		sc.Supplier_Product__c = sp.id;
		sc.Streams__c = 'Cardboard';
		sc.Time__c = '07:45';
		sc.Collection_Quantity__c = 1;
		sc.Supplier__c = s.id;
		sc.Suspension_Start_Date__c = system.today();
		sc.Reactivation_Start_Date__c = system.today() + 30;
		INSERT sc;

		Test.startTest();
		CollectionSuspendBatch.updateCollectionSuspendFlag();
		Test.stopTest();
	}
}