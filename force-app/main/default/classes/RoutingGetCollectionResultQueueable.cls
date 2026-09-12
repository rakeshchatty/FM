public without sharing class RoutingGetCollectionResultQueueable implements Queueable, Database.AllowsCallouts {

	private Integer jobId;
	private Integer pollCount = 1;

	public RoutingGetCollectionResultQueueable(Integer jobId) {
		this.jobId = jobId;
	}

	public RoutingGetCollectionResultQueueable(Integer jobId, Integer pollCount) {
		this(jobId);
		this.pollCount = pollCount;
	}

	public void execute(QueueableContext context) {
		getResult(jobId, pollCount);
	}

	private static void getResult(Integer jobId, Integer pollCount) {
		new RoutingGetCollectionResult(jobId, pollCount).getResult();
	}
}