public class LiveLocations {

	public static Map<Id, Boolean> hasLiveLocations(Set<Id> parentOrPartnershipIds) { 
		Map<Id, Boolean> doesAccountHaveLiveLocations = new Map<Id, Boolean>();
		for (Account account : fetchLiveLocations(parentOrPartnershipIds).values()) {
			doesAccountHaveLiveLocations.put(account.Id, !(account.ChildAccounts.isEmpty() && account.Accounts__r.isEmpty()));
		}
		return doesAccountHaveLiveLocations;
	}

	@InvocableMethod(label='Get Live Locations')
	public static List<Output> hasLiveLocations(List<Input> inputList) {
		Set<Id> parentOrPartnershipIds = new Set<Id>();

		for (Input input : inputList) {
			parentOrPartnershipIds.add(String.isNotBlank(input.parentId) ? input.parentId : null);
			parentOrPartnershipIds.add(String.isNotBlank(input.partnershipId) ? input.partnershipId : null);
		}

		List<Output> output = new List<Output>();
		Map<Id, Account> accountMap = fetchLiveLocations(parentOrPartnershipIds);
		for (Input input : inputList) {
			Integer parentLiveLocationCount = String.isBlank(input.parentId) ? null : accountMap.get(input.parentId).ChildAccounts.size();
			Integer partnershipLiveLocationCount = String.isBlank(input.partnershipId) ? null : accountMap.get(input.partnershipId).Accounts__r.size();
			output.add(hasLiveLocations(input, parentLiveLocationCount, partnershipLiveLocationCount));
		}
		return output;
	}

	@testVisible
	private static Output hasLiveLocations(Input input, Integer parentLiveLocationCount, Integer partnershipLiveLocationCount) {
		Output output = new Output();
		Integer ignoreLocationCount = String.isBlank(input.locationId) ? 0 : 1;
		output.doesParentHaveLiveLocations = parentLiveLocationCount > ignoreLocationCount;
		output.doesPartnershipHaveLiveLocations = partnershipLiveLocationCount > ignoreLocationCount;
		return output;
	}

	private static Map<Id, Account> fetchLiveLocations(Set<Id> parentOrPartnershipIds) {
		List<Account> accountList = [SELECT Id, (SELECT Id FROM ChildAccounts WHERE Enqix_Dead_Live__c = 'Live'), (SELECT Id FROM Accounts__r WHERE Enqix_Dead_Live__c = 'Live') FROM Account WHERE Id IN :parentOrPartnershipIds];
		Map<Id, Account> accountMap = new Map<Id, Account>();
		for (Account account : accountList) {
			accountMap.put(account.Id, account);
		}
		return accountMap;
	}

	public class Output {
		@InvocableVariable
		public Boolean doesParentHaveLiveLocations;
		@InvocableVariable
		public Boolean doesPartnershipHaveLiveLocations;
	}

	public class Input {
		@InvocableVariable
		public String locationId;
		@InvocableVariable
		public String parentId;
		@InvocableVariable
		public String partnershipId;
	}
}