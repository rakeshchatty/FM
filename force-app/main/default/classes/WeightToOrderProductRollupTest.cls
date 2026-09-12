@isTest
public class WeightToOrderProductRollupTest {

	public static Id pricebookId = Test.getStandardPricebookId();

	@TestSetup
	static void testSetup(){
		Account parentAcc = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parentAcc.Id, null);

		Product2 product = TestDataHelper.insertProduct('General Collection', '123', 'Collection');
		product.BinCategoryCode__c = 'COFFEE140';
        UPDATE product;

		PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = Test.getStandardPricebookId(),
            Product2Id = product.Id,
            UnitPrice = 1000,
            IsActive = true
        );
        Insert pbe;

		TestDataHelper.insertSupplier('First Mile Ltd');
		Order order = new Order(AccountId = location.Id,
									EffectiveDate = System.today(),
									Status = 'Confirmed',
									Pricebook2Id = Test.getStandardPricebookId(),
									Type = 'Regular');
		INSERT order;

		OrderItem orderItem = new OrderItem(OrderId = order.Id,
												Quantity =4,
												Product2Id = product.Id,
												PriceBookEntryId = pbe.Id,
												UnitPrice = 1500);
		INSERT orderItem;
	}

	@isTest
	static void testWeightToOrderProductRollup() {
		Account account = [SELECT Id FROM Account WHERE RecordType.Name ='Location' LIMIT 1];
		OrderItem orderItems = [SELECT Id FROM OrderItem LIMIT 1];

		Weight__c weight = new Weight__c();
        weight.Order_Product__c = orderItems.Id;
        weight.AD_KG_Per_Unit__c = 1;
        weight.Coffee_KG_Per_Unit__c = 2;
        weight.KWH_Produced_Per_Unit__c = 3;
        weight.Recycled_KG_Per_Unit__c = 4;
        weight.Tonnes_CO2_Saved_Per_Unit__c = 5;
        weight.Total_KG_Per_Unit__c = 6;
        weight.Trees_Saved_Per_Unit__c = 7;
        weight.WTE_KG_Per_Unit__c = 8;
        INSERT weight;

		List<OrderItem> orderItemList = [SELECT Coffee_KG_from_Weights__c, Total_KG_from_Weights__c FROM OrderItem];
		Assert.areEqual(2, orderItemList[0].Coffee_KG_from_Weights__c);
		Assert.areEqual(6, orderItemList[0].Total_KG_from_Weights__c);

        DELETE weight;
		List<OrderItem> orderItemsAfterDelete = [SELECT Coffee_KG_from_Weights__c, Total_KG_from_Weights__c FROM OrderItem];
		Assert.areEqual(null, orderItemsAfterDelete[0].Coffee_KG_from_Weights__c);
		Assert.areEqual(null, orderItemsAfterDelete[0].Total_KG_from_Weights__c);
	 }

}