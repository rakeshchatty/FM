public without sharing class RoutingPostCollectionJobInvoke {

	@InvocableMethod(Label='Sequence Dispatch')
	public static void sequence(List<List<Id>> dispatchIdLists) {
		Set<Id> dispatchIds = new Set<Id>();
		for (List<Id> dispatchIdList : dispatchIdLists) {
			dispatchIds.addAll(dispatchIdList);
		}
		Database.executebatch(new ClusterSequenceBatch(dispatchIds), 1);
	}
}