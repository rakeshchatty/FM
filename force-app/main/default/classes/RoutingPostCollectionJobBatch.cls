public without sharing class RoutingPostCollectionJobBatch implements Database.Batchable<Id> {

	List<Id> dispatchIds = null;

	public RoutingPostCollectionJobBatch(Set<Id> dispatchIds) {
		this.dispatchIds = new List<Id>(dispatchIds);
	}

	public Iterable<Id> start(Database.BatchableContext batchContext) {
		return dispatchIds;
	}

	public void execute(Database.BatchableContext batchContext, List<Id> dispatchIds) {
		System.enqueueJob(new RoutingPostCollectionJobQueueable(dispatchIds[0]));
	}

	public void finish(Database.BatchableContext batchContext) {}
}