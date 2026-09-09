public abstract without sharing class FileUpload {

	private static final String DELIMITER = ',';

	protected abstract String getOptionLabel();
	protected abstract String getFileReference();
	protected abstract Schema.SObjectType getObjectType();
	protected abstract Map<String, Schema.SObjectField> getFieldMap();

	public virtual FileUpload.Option getOption() {
		return new FileUpload.Option(getOptionLabel(), getFileReference());
	}

	public virtual String getDelimiter() {
		return DELIMITER;
	}

	public virtual String preview(List<Object> rows) {
		return 'Number of records to upload: ' + rows.size();
	}

	public virtual void process(List<Object> rows) {
		INSERT createSObject(rows);
	}

	protected virtual List<SObject> createSObject(List<Object> rows) {
		List<SObject> sObjects = new List<SObject>();

		Schema.SObjectType objectType = getObjectType();
		for (Object row : rows) {
			sObjects.add(createSObject(objectType, (Map<Object, Object>)row));
		}

		return sObjects;
	}

	protected virtual SObject createSObject(Schema.SObjectType objectType, Map<Object, Object> row) {
		SObject sObj = objectType.newSObject();
		String columnHeader, value;
		for (Object columnHeaderObj : row.keySet()) {
			columnHeader = (String)columnHeaderObj;
			value = String.valueOf(row.get(columnHeader));
			if (String.isBlank(value)) {
				continue;
			}
			addField(sObj, getFieldName(columnHeader), value);
		}

		return sObj;
	}

	protected virtual void addField(SObject sObj, String fieldName, Object value) {
		sObj.put(fieldName, castValue(value, getFieldType(fieldName)));
	}

	protected virtual String getFieldName(String columnHeader) {
		return columnHeader;
	}

	protected virtual Schema.DisplayType getFieldType(String fieldName) {
		return getFieldMap().get(fieldName).getDescribe().getType();
	}

	protected Object castValue(Object valueObj, Schema.DisplayType fieldType) {
		String value = String.valueOf(valueObj);
		switch on fieldType {
			when DOUBLE {
				return Decimal.valueOf(value);
			}
			when INTEGER {
				return Integer.valueOf(value);
			}
			when DATE {
				return Date.valueOf(value);
			}
			when DATETIME {
				return DateTime.valueOf(value);
			}
			when else {
				return value;
			}
		}
	}

	public class Option {
		@AuraEnabled public String label;
		@AuraEnabled public String value;

		public Option(String label, String value) {
			this.label = label;
			this.value = value;
		}
	}
}