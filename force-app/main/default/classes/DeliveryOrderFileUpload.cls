public with sharing class DeliveryOrderFileUpload extends FileUpload{
    public static final String FILE_REFERENCE = 'DeliveryOrder';
	private static final String LABEL = 'Delivery Order';
	private static final String DELIMITER = ',';
    private static final Map<String, String> FIELDS_TO_PROCESS = new Map<String, String>{'OrderId'=>'Order__c',
																						'Service Time' => 'ServiceTime__c',
																						'Demand' => 'Demand__c',
                                                                                        'serviceType' => 'ServiceType__c',
                                                                                        'RouteDate' => 'RouteDate__c',
																						'SkillSetProperty' => 'SkillSet__c'};

	private static final Schema.SObjectType SOBJECT_TYPE = SObjectType.DeliveryOrder__c.getSobjectType();
	private static final Map<String, Schema.SObjectField> FIELD_MAP = SObjectType.DeliveryOrder__c.fields.getMap();

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
        DeliveryOrderGroup__c deliveryOrderGroup = new DeliveryOrderGroup__c();
        INSERT deliveryOrderGroup;
		List<SObject> sObjects = createSObject(rows);
        for (SObject sObj : sObjects) {
            sObj.put('DeliveryOrderGroup__c', deliveryOrderGroup.Id); 
			System.debug('Name-->'+ deliveryOrderGroup.Name);
        }
		List<Database.SaveResult> results = Database.insert(sObjects, false);
		LogRegister.createLogsUpsert(results, sObjects, 'Delivery Order - File Upload', 'Insert', 'DeliveryOrder__c', 'DeliveryOrderGroup__c');
	}

	protected override String getFieldName(String columnHeader) {
		return FIELDS_TO_PROCESS.get(columnHeader);
	}

	protected override void addField(SObject sObj, String fieldName, Object value) {
		if (!FIELDS_TO_PROCESS.values().contains(fieldName)) {
			return;
		}

		if (fieldName == 'RouteDate__c') {
			String dateStr = String.valueOf(value);
            List<String> dateParts = dateStr.substringBefore(' ').split('/');
            Date d = date.newInstance(Integer.valueOf(dateParts[2]), Integer.valueOf(dateParts[0]),  Integer.valueOf(dateParts[1]));
            value = d;
    }

    super.addField(sObj, fieldName, value);
 	}
    
}