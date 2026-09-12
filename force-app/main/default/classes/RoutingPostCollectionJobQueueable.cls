public without sharing class RoutingPostCollectionJobQueueable implements Queueable, Database.AllowsCallouts {

	private Id dispatchId;

	public RoutingPostCollectionJobQueueable(Id dispatchId) {
		this.dispatchId = dispatchId;
	}

	public void execute(QueueableContext context) {
		postJob(dispatchId);
	}

	private static void postJob(Id dispatchId) {
		new RoutingPostCollectionJob(dispatchId).postJob();
	}
}