public with sharing class DeliveryRouteFileUpload extends FileUpload{
    public static final String FILE_REFERENCE = 'DeliveryRoute';
	private static final String LABEL = 'Delivery Route';
	private static final String DELIMITER = ';';
    private static final Map<String, String> FIELDS_TO_PROCESS = new Map<String, String>{'routeId'=>'Name',
																						'startTime' => 'StartTime__c',
																						'maxRouteTime' => 'MaximumRouteTime__c',
																						'vehicleCapacity' => 'VehicleCapacity__c',
                                                                                        'startLocation' => 'StartLocation__c',
																						'rtePref' => 'RtePref__c',
                                                                                        'skillSetProperties' => 'SkillSet__c'};

	private static final Schema.SObjectType SOBJECT_TYPE = SObjectType.DeliveryRoute__c.getSobjectType();
	private static final Map<String, Schema.SObjectField> FIELD_MAP = SObjectType.DeliveryRoute__c.fields.getMap();

    protected override String getOptionLabel() {
		return LABEL;
	}

	protected override String getFileReference() {
		return FILE_REFERENCE;
	}

	protected override Schema.SObjectType getObjectType() {
		return SOBJECT_TYPE;
	}

	protected override Map<String, Schema.SObjectField> getFieldMap() {
		return FIELD_MAP;
	}

	public override String getDelimiter() {
		return DELIMITER;
	}

	public override void process(List<Object> rows) {
        DeliveryRouteGroup__c deliveryRouteGroup = new DeliveryRouteGroup__c();
        INSERT deliveryRouteGroup;
		List<SObject> sObjects = createSObject(rows);
        for (SObject sObj : sObjects) {
            sObj.put('DeliveryRouteGroup__c', deliveryRouteGroup.Id);
        }
		List<Database.SaveResult> results = Database.insert(sObjects, false);
		LogRegister.createLogsUpsert(results, sObjects, 'Delivery Route - File Upload', 'Insert', 'DeliveryRoute__c', 'DeliveryRouteGroup__c');
	}

	protected override String getFieldName(String columnHeader) {
		return FIELDS_TO_PROCESS.get(columnHeader);
	}

	protected override void addField(SObject sObj, String fieldName, Object value) {
		if (!FIELDS_TO_PROCESS.values().contains(fieldName)) {
			return;
		}
        if (fieldName == 'Date__c') {
			value = Date.parse(String.valueOf(value).left(10));
		}

		super.addField(sObj, fieldName, value);
 	}
}