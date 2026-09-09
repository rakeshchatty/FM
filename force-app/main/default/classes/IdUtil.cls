public without sharing class IdUtil {

	private static final String ID_PREFIX_ORDER = '801';

	public static boolean isOrder(String id) {
		return String.isNotBlank(id) && id.startsWith(ID_PREFIX_ORDER);
	}

	public static boolean isOrder(Id id) {
		return isOrder(String.valueOf(id));
	}

	public static Set<Id> extractId(List<SObject> sObjectList) {
		return extractId(sObjectList, 'Id');
	}

	public static Set<Id> extractId(List<SObject> sObjectList, Id recordTypeId) {
		return extractId(sObjectList, 'Id', recordTypeId);
	}

	public static Set<Id> extractId(List<SObject> sObjectList, String idFieldName) {
		return extractId(sObjectList, idFieldName, null);
	}

	public static Set<Id> extractId(List<SObject> sObjectList, String idFieldName, Id recordTypeId) {
		Set<Id> ids = new Set<Id>();
		if (sObjectList == null || sObjectList.size() == 0) return ids;

		if (recordTypeId == null) {
			for (SObject obj : sObjectList) {
				ids.add((Id)obj.get(idFieldName));
			}
		} else {
			for (SObject obj : sObjectList) {
				if (obj.get('RecordTypeId') == recordTypeId) {
					ids.add((Id)obj.get(idFieldName));
				}
			}
		}
		return ids;
	}
}