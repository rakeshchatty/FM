public without sharing class DispatchSequence {

	@InvocableMethod(Label='Sequence Dispatches')
	public static void sequence(List<Id> dispatchIds) {
		Database.executebatch(new ClusterSequenceBatch(dispatchIds), 1);
	}

	public static void sequenceMorningDispatches() {
		Database.executebatch(new ClusterSequenceBatch(getDispatchIds('AM')), 1);
	}

	public static void sequenceEveningDispatches() {
		Database.executebatch(new ClusterSequenceBatch(getDispatchIds('PM')), 1);
	}

	private static Set<Id> getDispatchIds(String roundType) {
		List<DailyDispatch__c> dispataches = [SELECT Id FROM DailyDispatch__c WHERE CreatedDate = TODAY AND Status__c = 'Created'
			AND RoundId__r.Type__c = 'Collection' AND RoundId__r.Round_Type__c = :roundType];

		return IdUtil.extractId(dispataches);
	}
}