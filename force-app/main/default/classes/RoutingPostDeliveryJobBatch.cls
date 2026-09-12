public without sharing class RoutingPostDeliveryJobBatch implements Database.Batchable<Id> {

	private List<Id> orderGroupIds;

	public RoutingPostDeliveryJobBatch(Set<Id> orderGroupIds) {
		this.orderGroupIds = new List<Id>(orderGroupIds);
	}

	public Iterable<Id> start(Database.BatchableContext batchContext) {
		return orderGroupIds;
	}

	public void execute(Database.BatchableContext batchContext, List<Id> orderGroupIds) {
		System.enqueueJob(new RoutingPostDeliveryJobQueueable(orderGroupIds[0]));
	}

	public void finish(Database.BatchableContext batchContext) {}
}