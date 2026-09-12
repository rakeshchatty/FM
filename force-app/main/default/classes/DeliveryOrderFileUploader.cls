public with sharing class DeliveryOrderFileUploader extends FileUploader {

	private static final String LABEL = 'Delivery Order';
	private static final String FILE_REFERENCE = 'DeliveryOrder';
	private static final Schema.SObjectType SOBJECT_TYPE = SObjectType.DeliveryOrder__c.getSobjectType();
	private static final Map<String, Schema.SObjectField> FIELD_MAP = SObjectType.DeliveryOrder__c.fields.getMap();
	private static final Map<String, String> FIELDS_TO_PROCESS = new Map<String, String> {
		'OrderId' => 'Order__c',
		'Service Time' => 'ServiceTime__c',
		'Demand' => 'Demand__c',
		'serviceType' => 'ServiceType__c',
		'SkillSetProperty' => 'SkillSet__c',
		'RouteDate' => 'RouteDate__c'
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

	protected override String getFieldName(String columnHeader) {
		return FIELDS_TO_PROCESS.get(columnHeader);
	}

	public override void process(List<Object> rows) {
		DeliveryOrderGroup__c deliveryOrderGroup = new DeliveryOrderGroup__c();
		INSERT deliveryOrderGroup;

		List<SObject> sObjects = createSObject(rows);
		for (SObject sObj : sObjects) {
			sObj.put('DeliveryOrderGroup__c', deliveryOrderGroup.Id);
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