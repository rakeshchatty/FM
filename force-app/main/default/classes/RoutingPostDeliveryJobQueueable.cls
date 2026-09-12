public without sharing class RoutingPostDeliveryJobQueueable implements Queueable, Database.AllowsCallouts {

	private Id orderGroupId;

	public RoutingPostDeliveryJobQueueable(Id orderGroupId) {
		this.orderGroupId = orderGroupId;
	}

	public void execute(QueueableContext context) {
		postJob(orderGroupId);
	}

	private static void postJob(Id orderGroupId) {
		new RoutingPostDeliveryJob(orderGroupId).postJob();
	}
}