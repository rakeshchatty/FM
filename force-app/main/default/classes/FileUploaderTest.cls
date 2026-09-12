@isTest
private class FileUploaderTest {

	@testSetup
	static void setup() {
		TestDataHelper.insertSupplierFirstMile();
	}

	@isTest
	static void uploadDeliveryRouteFile() {
		String fileReference = 'DeliveryRoute';
		List<FileUploader.Option> options = FileUploadController.getOptions();
		Assert.isTrue(new List<String>{options[0].value, options[1].value}.contains(fileReference));
		Assert.isTrue(new List<String>{options[0].label, options[1].label}.contains('Delivery Route'));

		Assert.areEqual(';', FileUploadController.getDelimiter(fileReference));

		Depot__c depot = TestDataHelper.insertDepot();
		Map<Object, Object> record = new Map<Object, Object>{
			'routeId' => 'XYZ',
			'startTime' => '11:00',
			'maxRouteTime' => '08:00',
			'vehicleCapacity' => 100,
			'startLocation' => depot.Index__c,
			'endLocation' => depot.Index__c,
			'rtePref' => 1,
			'skillSetProperties' => '"A","V","PM","PMC","WC","SC"',
			'invalidColumn' => 'invalid value'
		};
		List<Map<Object, Object>> rows = new List<Map<Object, Object>>{record};
		Assert.areEqual('Number of records to upload: 1', FileUploadController.preview(fileReference, rows));

		Test.startTest();
		FileUploadController.process(fileReference, rows);
		Test.stopTest();
		Assert.areEqual(1, [SELECT Id FROM DeliveryRouteGroup__c].size());
		Assert.areEqual(1, [SELECT Id FROM DeliveryRoute__c].size());
	}

	@isTest
	static void uploadDeliveryOrderFile() {
		String fileReference = 'DeliveryOrder';
		List<FileUploader.Option> options = FileUploadController.getOptions();
		Assert.isTrue(new List<String>{options[0].value, options[1].value}.contains(fileReference));
		Assert.isTrue(new List<String>{options[0].label, options[1].label}.contains('Delivery Order'));

		Assert.areEqual(',', FileUploadController.getDelimiter(fileReference));

		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
        Order order = TestDataHelper.insertOrder(location.Id);
		Map<Object, Object> record = new Map<Object, Object>{
			'OrderId' => order.Id,
			'Service Time' => 150,
			'Demand' => 50,
			'serviceType' => 'DEL',
			'SkillSetProperty' => '"A","V","PM","PMC","WC","SC"',
			'RouteDate' => System.today(),
			'invalidColumn' => 'invalid value'
		};
		List<Map<Object, Object>> rows = new List<Map<Object, Object>>{record};
		Assert.areEqual('Number of records to upload: 1', FileUploadController.preview(fileReference, rows));

		Test.startTest();
		FileUploadController.process(fileReference, rows);
		Test.stopTest();
		Assert.areEqual(1, [SELECT Id FROM DeliveryOrderGroup__c].size());
		Assert.areEqual(1, [SELECT Id FROM DeliveryOrder__c].size());
	}

	@isTest
	static void uploadInvalidFile() {
		try {
			FileUploadController.getDelimiter('InvalidFileReference');
			Assert.fail();
		} catch(Exception e) {
			// Exception expected
		}
	}
}