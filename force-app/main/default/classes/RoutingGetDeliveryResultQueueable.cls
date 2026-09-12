public without sharing class RoutingGetDeliveryResultQueueable implements Queueable, Database.AllowsCallouts {

	private Integer jobId;
	private Integer pollCount = 1;

	public RoutingGetDeliveryResultQueueable(Integer jobId) {
		this.jobId = jobId;
	}

	public RoutingGetDeliveryResultQueueable(Integer jobId, Integer pollCount) {
		this(jobId);
		this.pollCount = pollCount;
	}

	public void execute(QueueableContext context) {
		getResult(jobId, pollCount);
	}

	private static void getResult(Integer jobId, Integer pollCount) {
		new RoutingGetDeliveryResult(jobId, pollCount).getResult();
	}
}