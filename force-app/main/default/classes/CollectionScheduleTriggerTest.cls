@isTest
private class CollectionScheduleTriggerTest {

	private static Id LOCATION_ACCOUNT_RECORDTYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Location').getRecordTypeId();
	private static Id WTN_COMPLIANCE_DOC_RECORDTYPE_ID = Schema.SObjectType.Compliance_Doc__c.getRecordTypeInfosByName().get('Waste Transfer Notes').getRecordTypeId();

	@testSetup
	private static void setup() {
		Product_Category__c productCategory = new Product_Category__c(Name = 'Test Product Category', Enqix_Id__c = 12345, Product_Category_Key__c = 'Test Product Category Key');
		INSERT productCategory;

		Waste_Category__c  wasteCategory = new Waste_Category__c(Name = 'Cardboard Waste', Codes__c = '123456');
		INSERT wasteCategory;

		Container_Type__c containerType = TestDataHelper.insertContainerType('Bin');

		Product2 product = TestDataHelper.createProduct('Test Product', '12355321', 'Collection', productCategory.Id, wasteCategory.Id, containerType.Id, '264');
		INSERT product;

		Suppliers__c supplier = TestDataHelper.insertSupplier('First Mile Ltd');

		Supplier_Product__c supplierProduct = new Supplier_Product__c(Name = 'Test Supplier Product', Supplier__c = supplier.Id, Product__c = product.Id, Enqix_UID__c = '1233');
		INSERT supplierProduct;

		Account parent = TestDataHelper.createAccount();
		parent.IsBinCollectionAdvanceInvoiced__c = true;
		INSERT parent;
		Account location = TestDataHelper.createLocation(parent.Id, null);
		location.Price_Book__c = Test.getStandardPricebookId();
		location.Enqix_Dead_Live__c = 'Live';
		INSERT location;

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Tuesday;Wednesday;Thursday', Time__c = '18:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Saturday;Sunday', Time__c = '20:30'));
		INSERT collectionSchedules;
	}

	@isTest
	private static void testController() {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		CollectionScheduleController.getCollections(location.Id);
	}

	@isTest
	private static void testInsert() {
		List<Schedule__c> collectionSchedules = querySchedules();
		System.assertEquals(6, collectionSchedules.size());
		assertSchedule(collectionSchedules[0], 'Monday', 'Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[1], 'Tuesday', 'Monday,Wednesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[2], 'Wednesday', 'Monday,Tuesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[3], 'Thursday', 'Monday,Tuesday,Wednesday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[4], 'Saturday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Sunday');
		assertSchedule(collectionSchedules[5], 'Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday');

		List<CollectionAggregator__c> collectionAggregators = queryAggregators();
		System.assertEquals(2, collectionAggregators.size());
		assertAggregator(collectionAggregators[0], 'Monday,Tuesday,Wednesday,Thursday', 'Friday,Saturday,Sunday', '18:00');
		assertAggregator(collectionAggregators[1], 'Saturday,Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday', '20:30');
	}

	@isTest
	private static void testUpdateWithNoChange() {
		List<Schedule__c> collectionSchedules = [SELECT Id FROM Schedule__c WHERE Days__c IN ('Monday', 'Tuesday', 'Wednesday')
												ORDER BY Monday_Collection__c DESC, Tuesday_Collection__c DESC, Wednesday_Collection__c DESC];
		UPDATE collectionSchedules;

		testInsert();
	}

	@isTest
	private static void testUpdate2Of4Days() {
		List<Schedule__c> collectionSchedules = [SELECT Id FROM Schedule__c WHERE Days__c IN ('Monday', 'Tuesday', 'Wednesday')
												ORDER BY Monday_Collection__c DESC, Tuesday_Collection__c DESC, Wednesday_Collection__c DESC];
		collectionSchedules[0].Time__c = '20:30';	// Monday
		collectionSchedules[1].Time__c = '20:30';	// Tuesday
		collectionSchedules[2].Time__c = '18:00';	// Wednesday, no change
		UPDATE collectionSchedules;

		collectionSchedules = querySchedules();
		System.assertEquals(6, collectionSchedules.size());
		assertSchedule(collectionSchedules[0], 'Monday', 'Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[1], 'Tuesday', 'Monday,Wednesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[2], 'Wednesday', 'Monday,Tuesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[3], 'Thursday', 'Monday,Tuesday,Wednesday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[4], 'Saturday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Sunday');
		assertSchedule(collectionSchedules[5], 'Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday');

		List<CollectionAggregator__c> collectionAggregators = queryAggregators();
		System.assertEquals(2, collectionAggregators.size());
		assertAggregator(collectionAggregators[0], 'Monday,Tuesday,Saturday,Sunday', 'Wednesday,Thursday,Friday', '20:30');
		assertAggregator(collectionAggregators[1], 'Wednesday,Thursday', 'Monday,Tuesday,Friday,Saturday,Sunday', '18:00');
	}

	@isTest
	private static void testUpdate4Of4Days() {
		List<Schedule__c> collectionSchedules = [SELECT Id FROM Schedule__c WHERE Days__c IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday')];
		collectionSchedules[0].Time__c = '20:30';
		collectionSchedules[1].Time__c = '20:30';
		collectionSchedules[2].Time__c = '20:30';
		collectionSchedules[3].Time__c = '20:30';
		UPDATE collectionSchedules;

		collectionSchedules = querySchedules();
		System.assertEquals(6, collectionSchedules.size());
		assertSchedule(collectionSchedules[0], 'Monday', 'Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[1], 'Tuesday', 'Monday,Wednesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[2], 'Wednesday', 'Monday,Tuesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[3], 'Thursday', 'Monday,Tuesday,Wednesday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[4], 'Saturday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Sunday');
		assertSchedule(collectionSchedules[5], 'Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday');

		List<CollectionAggregator__c> collectionAggregators = queryAggregators();
		System.assertEquals(1, collectionAggregators.size());
		assertAggregator(collectionAggregators[0], 'Monday,Tuesday,Wednesday,Thursday,Saturday,Sunday', 'Friday', '20:30');
	}

	@isTest
	private static void testDelete2() {
		List<Schedule__c> collectionSchedules = [SELECT Id FROM Schedule__c WHERE Days__c IN ('Monday', 'Tuesday')];
		DELETE collectionSchedules;

		collectionSchedules = querySchedules();
		System.assertEquals(4, collectionSchedules.size());
		assertSchedule(collectionSchedules[0], 'Wednesday', 'Monday,Tuesday,Thursday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[1], 'Thursday', 'Monday,Tuesday,Wednesday,Friday,Saturday,Sunday');
		assertSchedule(collectionSchedules[2], 'Saturday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Sunday');
		assertSchedule(collectionSchedules[3], 'Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday');

		List<CollectionAggregator__c> collectionAggregators = queryAggregators();
		System.assertEquals(2, collectionAggregators.size());
		assertAggregator(collectionAggregators[0], 'Wednesday,Thursday', 'Monday,Tuesday,Friday,Saturday,Sunday', '18:00');
		assertAggregator(collectionAggregators[1], 'Saturday,Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday', '20:30');
	}

	@isTest
	private static void testDelete4() {
		List<Schedule__c> collectionSchedules = [SELECT Id FROM Schedule__c WHERE Days__c IN ('Monday', 'Tuesday', 'Wednesday', 'Thursday')];
		DELETE collectionSchedules;

		collectionSchedules = querySchedules();
		System.assertEquals(2, collectionSchedules.size());
		assertSchedule(collectionSchedules[0], 'Saturday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Sunday');
		assertSchedule(collectionSchedules[1], 'Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday');

		List<CollectionAggregator__c> collectionAggregators = queryAggregators();
		System.assertEquals(1, collectionAggregators.size());
		assertAggregator(collectionAggregators[0], 'Saturday,Sunday', 'Monday,Tuesday,Wednesday,Thursday,Friday', '20:30');
	}

	@isTest
	private static void testInvalidInsertFailure() {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		Suppliers__c supplier = [SELECT Id FROM Suppliers__c];
		Supplier_Product__c supplierProduct = [SELECT Id FROM Supplier_Product__c];

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday;Tuesday;Wednesday', Time__c = '2A:00'));	// Invalid time format
		try {
			INSERT collectionSchedules;
			System.assert(false);
		} catch (DmlException e) {
			System.assertEquals('Time must be in HH:MM format. E.g. 07:45', e.getDmlMessage(0));
		}
	}

	@isTest
	private static void testDuplicateInsertFailure() {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		Suppliers__c supplier = [SELECT Id FROM Suppliers__c];
		Supplier_Product__c supplierProduct = [SELECT Id FROM Supplier_Product__c];

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();

		// Duplicates within newly inserted records
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '21:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday;Tuesday;Wednesday;Thursday', Time__c = '21:00')); // Duplicate Monday
		try {
			INSERT collectionSchedules;
			System.assert(false);
		} catch (DmlException e) {
			System.assertEquals(Label.MsgDuplicateCollectionSchedule, e.getDmlMessage(0));
		}

		// Duplicates between newly inserted records and existing records
		collectionSchedules.clear();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '21:00'));    // Unique
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '18:00'));    // Duplicate
		try {
			INSERT collectionSchedules;
			System.assert(false);
		} catch (DmlException e) {
			System.assertEquals(Label.MsgDuplicateCollectionSchedule, e.getDmlMessage(0));
		}

		// Invalid time format
		collectionSchedules.clear();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '2A:00'));	// Invalid time format
		try {
			INSERT collectionSchedules;
			System.assert(false);
		} catch (DmlException e) {
			System.assertEquals('Time must be in HH:MM format. E.g. 07:45', e.getDmlMessage(0));
		}
	}

	@isTest
	private static void testDuplicateUpdateFailure() {
		Account location = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Location' LIMIT 1];
		Suppliers__c supplier = [SELECT Id FROM Suppliers__c];
		Supplier_Product__c supplierProduct = [SELECT Id FROM Supplier_Product__c];

		List<Schedule__c> collectionSchedules = new List<Schedule__c>();
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '21:00'));
		collectionSchedules.add(new Schedule__c(Location__c = location.id, Supplier__c = supplier.id, Supplier_Product__c = supplierProduct.id, Collection_Quantity__c = 10,
												Days__c = 'Monday', Time__c = '21:30'));

		Database.SaveResult[] results = Database.insert(collectionSchedules);
		System.assert(results[0].isSuccess());
		System.assert(results[1].isSuccess());

		// Duplicates within updated records
		collectionSchedules[0].Time__c = '23:00'; // Duplicate
		collectionSchedules[1].Time__c = '23:00'; // Duplicate
		try {
			UPDATE collectionSchedules;
			System.assert(false);
		} catch (DmlException e) {
			System.assertEquals(Label.MsgDuplicateCollectionSchedule, e.getDmlMessage(0));
		}

		// Duplicates between updated records and existing records
		collectionSchedules[0].Time__c = '21:00'; // No change
		collectionSchedules[1].Time__c = '18:00'; // Duplicate
		try {
			UPDATE collectionSchedules;
			System.assert(false);
		} catch (DmlException e) {
			System.assertEquals(Label.MsgDuplicateCollectionSchedule, e.getDmlMessage(0));
		}
	}

	private static List<Schedule__c> querySchedules() {
		return [SELECT Monday_Collection__c, Tuesday_Collection__c, Wednesday_Collection__c, Thursday_Collection__c, Friday_Collection__c, Saturday_Collection__c, Sunday_Collection__c
				FROM Schedule__c
				ORDER BY Monday_Collection__c DESC NULLS LAST, Tuesday_Collection__c DESC NULLS LAST, Wednesday_Collection__c DESC NULLS LAST, Thursday_Collection__c DESC NULLS LAST,
					Friday_Collection__c DESC NULLS LAST, Saturday_Collection__c DESC NULLS LAST, Sunday_Collection__c DESC NULLS LAST];
	}

	private static List<CollectionAggregator__c> queryAggregators() {
		return [SELECT Monday__c, Tuesday__c, Wednesday__c, Thursday__c, Friday__c, Saturday__c, Sunday__c
				FROM CollectionAggregator__c
				ORDER BY Monday__c NULLS LAST, Wednesday__c NULLS LAST, Saturday__c NULLS LAST];
	}

	private static void assertSchedule(Schedule__c schedule, String csvDaysEnabled, String csvDaysDisabled) {
		assertSchedule(schedule, csvDaysEnabled, true);
		assertSchedule(schedule, csvDaysDisabled, false);
	}
	private static void assertSchedule(Schedule__c schedule, String csvDays, Boolean isEnabled) {
		for (String dayOfWeek : csvDays.split(',')) {
			System.assertEquals(isEnabled, (Boolean)schedule.get(dayOfWeek + '_Collection__c'));
		}
	}

	private static void assertAggregator(CollectionAggregator__c aggregator, String csvDaysEnabled, String csvDaysDisabled, String collectionTime) {
		assertAggregator(aggregator, csvDaysEnabled, collectionTime);
		assertAggregator(aggregator, csvDaysDisabled, null);
	}
	private static void assertAggregator(CollectionAggregator__c aggregator, String csvDays, String collectionTime) {
		for (String dayOfWeek : csvDays.split(',')) {
			System.assertEquals(collectionTime, (String)aggregator.get(dayOfWeek + '__c'));
		}
	}
}