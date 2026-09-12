public without sharing class WtnWasteCategoryOnSchedule {

	private static String KEY_FORMAT = '{0}-{1}-{2}';

	public static void apply(List<Schedule__c> schedules) {
		Set<Id> locationIds = new Set<Id>();
		Set<Id> supplierIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		for (Schedule__c schedule : schedules) {
			locationIds.add(schedule.Location__c);
			supplierIds.add(schedule.Supplier__c);
			productIds.add(schedule.ProductId__c);
		}

		Map<String, Id> keyToWasteCategory = getWtnWasteCategoryMap(locationIds, supplierIds, productIds);
		if (keyToWasteCategory.isEmpty()) {
			return;
		}

		apply(schedules, keyToWasteCategory);
	}

	public static void apply(List<WTN_Waste_Category__c> wtnWasteCategories) {
		Set<Id> locationIds = new Set<Id>();
		Set<Id> supplierIds = new Set<Id>();
		Set<Id> productIds = new Set<Id>();
		for (WTN_Waste_Category__c wtnWasteCategory : wtnWasteCategories) {
			locationIds.add(wtnWasteCategory.WTN__r.Account__c);
			supplierIds.add(wtnWasteCategory.WTN__r.Contractor__c);
			productIds.add(wtnWasteCategory.Product__c);
		}

		List<Schedule__c> schedules = [SELECT Location__c, Supplier__c, ProductId__c FROM Schedule__c
			WHERE Location__c IN :locationIds AND Supplier__c IN :supplierIds AND ProductId__c IN :productIds
			AND (End_Date__c = null OR End_Date__c >= TODAY)];

		Map<String, Id> keyToWasteCategory = getWtnWasteCategoryMap(wtnWasteCategories);
		schedules = filterByWasteCatgory(schedules, keyToWasteCategory);
		apply(schedules, keyToWasteCategory);

		UPDATE schedules;
	}

	private static List<Schedule__c> filterByWasteCatgory(List<Schedule__c> schedules, Map<String, Id> keyToWasteCategory) {
		List<Schedule__c> filteredSchedules = new List<Schedule__c>();
		for (Schedule__c schedule : schedules) {
			if (keyToWasteCategory.containsKey(key(schedule))) {
				filteredSchedules.add(schedule);
			}
		}
		return filteredSchedules;
	}

	private static void apply(List<Schedule__c> schedules, Map<String, Id> keyToWasteCategory) {
		for (Schedule__c schedule : schedules) {
			schedule.WtnWasteCategory__c = keyToWasteCategory.get(key(schedule));
		}
	}

	private static Map<String, Id> getWtnWasteCategoryMap(List<WTN_Waste_Category__c> wtnWasteCategories) {
		Map<String, Id> keyToWasteCategory = new Map<String, Id>();
		for (WTN_Waste_Category__c wtnWasteCategory : wtnWasteCategories) {
			keyToWasteCategory.put(key(wtnWasteCategory), wtnWasteCategory.Id);
		}

		return keyToWasteCategory;
	}

	private static Map<String, Id> getWtnWasteCategoryMap(Set<Id> locationIds, Set<Id> supplierIds, Set<Id> productIds) {
		List<WTN_Waste_Category__c> wtnWasteCategories = [SELECT WTN__r.Account__c, WTN__r.Contractor__c, Product__c FROM WTN_Waste_Category__c
			WHERE WTN__r.IsActive__c = true AND WTN__r.Name LIKE 'Season Ticket WTN%'
			AND WTN__r.Account__c IN :locationIds AND WTN__r.Contractor__c IN :supplierIds AND Product__c IN :productIds];

		return getWtnWasteCategoryMap(wtnWasteCategories);
	}

	private static String key(Schedule__c schedule) {
		return String.format(KEY_FORMAT, new String[]{schedule.Location__c, schedule.Supplier__c, schedule.ProductId__c});
	}

	private static String key(WTN_Waste_Category__c wtnWasteCategory) {
		return String.format(KEY_FORMAT, new String[]{wtnWasteCategory.WTN__r.Account__c, wtnWasteCategory.WTN__r.Contractor__c, wtnWasteCategory.Product__c});
	}
}