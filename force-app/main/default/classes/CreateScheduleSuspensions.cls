public without sharing class CreateScheduleSuspensions {
	private static final Date TODAY = Date.today();
	private static final Date TOMORROW = Date.today().addDays(1);

	@InvocableMethod(Label='Create Schedule Suspensions')
	public static void create(List<Input> inputs) {
		if (inputs.isEmpty()){
			return;
		}

		List<ScheduleSuspension__c> scheduleSuspensions;
		List<String> newAggregatorSuspensionKeys;
		CollectionAggregator__c newAggregator;
		for (Input input : inputs) {
			if (input.amendedAggregatorId == null || input.newSchedules.isEmpty()) {
				return;
			}

			newAggregatorSuspensionKeys = new List<String>();
			newAggregator = [SELECT CollectionAggregator__c, CollectionAggregator__r.IsSuspended__c FROM Schedule__c WHERE Id IN :input.newSchedules ORDER BY CreatedDate DESC LIMIT 1].CollectionAggregator__r;
			for (ScheduleSuspension__c scheduleSuspension : [SELECT Aggregator__c, SuspensionDate__c, ReactivationDate__c, IsEveryYear__c FROM ScheduleSuspension__c WHERE Aggregator__c = :newAggregator.Id AND ReactivationDate__c > TODAY]) {
				newAggregatorSuspensionKeys.add(scheduleSuspension.Aggregator__c + '-' + scheduleSuspension.SuspensionDate__c + '-' + scheduleSuspension.ReactivationDate__c);
			}

			scheduleSuspensions = new List<ScheduleSuspension__c>();
			String key;
			for (ScheduleSuspension__c scheduleSuspension : [SELECT Aggregator__c, SuspensionDate__c, ReactivationDate__c, IsEveryYear__c FROM ScheduleSuspension__c WHERE Aggregator__c = :input.amendedAggregatorId AND ReactivationDate__c > TODAY AND IsActive__c = TRUE]) {
				key = scheduleSuspension.Aggregator__c + '-' + scheduleSuspension.SuspensionDate__c + '-' + scheduleSuspension.ReactivationDate__c;
				if (!newAggregatorSuspensionKeys.contains(key) && scheduleSuspension.SuspensionDate__c > TODAY) {
					scheduleSuspensions.add(new ScheduleSuspension__c(Aggregator__c = newAggregator.Id, SuspensionDate__c = scheduleSuspension.SuspensionDate__c, ReactivationDate__c = scheduleSuspension.ReactivationDate__c, IsEveryYear__c = scheduleSuspension.IsEveryYear__c));
				} else if (!newAggregatorSuspensionKeys.contains(key) && scheduleSuspension.SuspensionDate__c < TODAY && scheduleSuspension.ReactivationDate__c > TOMORROW && !newAggregator.IsSuspended__c) {
					scheduleSuspensions.add(new ScheduleSuspension__c(Aggregator__c = newAggregator.Id, SuspensionDate__c = TOMORROW, ReactivationDate__c = scheduleSuspension.ReactivationDate__c, IsEveryYear__c = scheduleSuspension.IsEveryYear__c));
				}
			}

			if (!scheduleSuspensions.isEmpty()) {
				Database.SaveResult[] results = Database.insert(scheduleSuspensions, false);
				LogRegister.createLogsUpsert(results, scheduleSuspensions, 'Create Schedule Suspensions', 'Insert', 'ScheduleSuspension__c', 'Aggregator__c');
			}

		}
	}

	public class Input {
		@InvocableVariable(required=true label='New Schedules')
		public List<Schedule__c> newSchedules;
		@InvocableVariable(required=true label='Amended Aggregator Id')
		public Id amendedAggregatorId;
	}
}