public with sharing class DeliveryRouteFileUploader extends FileUploader {

	private static final String DELIMITER = ';';
	private static final String LABEL = 'Delivery Route';
	private static final String FILE_REFERENCE = 'DeliveryRoute';
	private static final Schema.SObjectType SOBJECT_TYPE = SObjectType.DeliveryRoute__c.getSobjectType();
	private static final Map<String, Schema.SObjectField> FIELD_MAP = SObjectType.DeliveryRoute__c.fields.getMap();
	private static final Map<String, String> FIELDS_TO_PROCESS = new Map<String, String> {
		'routeId' => 'Name',
		'startTime' => 'StartTime__c',
		'maxRouteTime' => 'MaxRouteTime__c',
		'vehicleCapacity' => 'VehicleCapacity__c',
		'startLocation' => 'StartDepotIndex__c',
		'endLocation' => 'EndDepotIndex__c',
		'rtePref' => 'Preference__c',
		'skillSetProperties' => 'SkillSet__c'
	};

	public override String getFileReference() {
		return FILE_REFERENCE;
	}

	protected override String getOptionLabel() {
		return LABEL;
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

	protected override String getFieldName(String columnHeader) {
		return FIELDS_TO_PROCESS.get(columnHeader);
	}

	public override void process(List<Object> rows) {
		DeliveryRouteGroup__c deliveryRouteGroup = new DeliveryRouteGroup__c(Name = 'DlvyRtGrp-' + System.now());
		INSERT deliveryRouteGroup;

		List<SObject> sObjects = createSObject(rows);
		for (SObject sObj : sObjects) {
			sObj.put('DeliveryRouteGroup__c', deliveryRouteGroup.Id);
		}
		INSERT sObjects;
	}

	protected override void addField(SObject sObj, String fieldName, Object value) {
		if (!FIELDS_TO_PROCESS.values().contains(fieldName)) {
			return;
		}

		if (fieldName == 'SkillSet__c') {
			value = String.valueOf(value).replace('"', '');
		}

		super.addField(sObj, fieldName, value);
 	}
}