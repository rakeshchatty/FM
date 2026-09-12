@isTest
public without sharing class AdditionalChargesTest {
	@TestSetup
	static void processTest() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, Null);

		Container_Type__c externalBin = TestDataHelper.insertContainerType('External Bin', 'Bin');
		Container_Type__c sack = TestDataHelper.insertContainerType('Sack', 'Bag');

		List<Product2> products = new List<Product2>();
		Product2 binProduct = TestDataHelper.createProduct('Product 1','P0001', 'Delivery', null);
		binProduct.Container_Type__c = externalBin.Id;
		binProduct.IncludeFuelSurcharge__c = true;
		products.add(binProduct);
		Product2 sackProduct = TestDataHelper.createProduct('Product 2','P0002', 'Delivery', null);
		sackProduct.Container_Type__c = sack.Id;
		sackProduct.IncludeFuelSurcharge__c = true;
		products.add(sackProduct);
		INSERT products;

		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[0].Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(products[1].Id, 10));
		INSERT pricebookEntries;
	}

	@isTest
	static void processProductDeliveryTest() {
		Product2 binChargeProduct = TestDataHelper.insertProduct('Bin Charge','P0003', 'Delivery', null);
		Product2 bagChargeProduct = TestDataHelper.insertProduct('Bag Charge','P0004', 'Delivery', null);

		List<PricebookEntry> pricebookEntries = new List<PricebookEntry>();
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(binChargeProduct.Id, 10));
		pricebookEntries.add(TestDataHelper.createStandardPricebookEntry(bagChargeProduct.Id, 5));
		INSERT pricebookEntries;

		TestDataHelper.insertAdditionalChargeSetting(binChargeProduct.Id, bagChargeProduct.Id, 'External Bin', 'Sack');

		Account parent = [SELECT Id FROM Account WHERE RecordType.Name = 'Account' LIMIT 1];
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' AND ParentId = :parent.Id LIMIT 1];

		AdditionalCharges.OrderData orderData = new AdditionalCharges.OrderData();
		orderData.locationId = location.Id;
		orderData.orderItems = new List<AdditionalCharges.OrderItemData>();
		for (Product2 product : [SELECT Id FROM Product2 WHERE Name IN ('Product 1', 'Product 2')]) {
			AdditionalCharges.OrderItemData orderItem = new AdditionalCharges.OrderItemData();
			orderItem.productId = product.Id;
			orderItem.quantity = 5;
			orderItem.unitPrice = 10;
			orderData.orderItems.add(orderItem);
		}

		RestRequest request = new RestRequest();
		request.addHeader('httpMethod', 'POST');
		request.requestUri = '/services/apexrest/ProcessAdditionCharges/';
		request.requestBody = Blob.valueOf(JSON.serialize(orderData));

		RestResponse response = new RestResponse();
		RestContext.request = request;
		RestContext.response = response;

		Test.startTest();
		List<AdditionalCharges.OrderItemData> orderItemResult = AdditionalCharges.process();
		Test.stopTest();

		Assert.areEqual(2, orderItemResult.size());
	}

	@isTest
	static void processFuelSurchargeTest() {
		Product2 fuelSurchargeProduct = TestDataHelper.insertProduct('Fuel Surcharge','P0005', 'Delivery', null);
		TestDataHelper.insertFuelSurchargeSetting(fuelSurchargeProduct.Id, 1.75);

		TestDataHelper.insertStandardPricebookEntry(fuelSurchargeProduct.Id, 0);

		Account parent = [SELECT Id FROM Account WHERE RecordType.Name = 'Account' LIMIT 1];
		Account location = [SELECT Id FROM Account WHERE RecordType.Name = 'Location' AND ParentId = :parent.Id LIMIT 1];

		AdditionalCharges.OrderData orderData = new AdditionalCharges.OrderData();
		orderData.locationId = location.Id;
		orderData.orderItems = new List<AdditionalCharges.OrderItemData>();
		for (Product2 product : [SELECT Id FROM Product2 WHERE IncludeFuelSurcharge__c =  true]) {
			AdditionalCharges.OrderItemData orderItem = new AdditionalCharges.OrderItemData();
			orderItem.productId = product.Id;
			orderItem.quantity = 5;
			orderItem.unitPrice = 10;
			orderData.orderItems.add(orderItem);
		}

		RestRequest request = new RestRequest();
		request.addHeader('httpMethod', 'POST');
		request.requestUri = '/services/apexrest/ProcessAdditionCharges/';
		request.requestBody = Blob.valueOf(JSON.serialize(orderData));

		RestResponse response = new RestResponse();
		RestContext.request = request;
		RestContext.response = response;

		Test.startTest();
		List<AdditionalCharges.OrderItemData> orderItemResult = AdditionalCharges.process();
		Test.stopTest();

		Assert.areEqual(1, orderItemResult.size());
	}
}