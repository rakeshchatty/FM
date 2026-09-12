public without sharing class DispatchCreationInvocable {

	@InvocableMethod(label='Execute Dispatch Creation Batch')
	public static void invoke(List<Id> roundIds) {
		Database.executebatch(new DispatchCreationBatch(new Set<Id>(roundIds)), 5);
	}
}