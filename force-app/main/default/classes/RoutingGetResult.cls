public without sharing abstract class RoutingGetResult {

	private static final List<String> STATUS_IN_PROGRESS = new List<String>{'Loading', 'InQueue', 'Routing'};

	protected Integer jobId;
	protected Integer pollCount;

	protected RoutingGetResult(Integer jobId, Integer pollCount) {
		this.jobId = jobId;
		this.pollCount = pollCount;
	}

	protected abstract void enqueue();
	protected abstract void updateJobError(String status, String message);
	protected abstract void processResult(RoutingResponse routingResponse);
	protected abstract String key(sObject record);

	public void getResult() {
		try {
			get();
		} catch (Exception e) {
			updateJobError(e.getTypeName().contains('RoutingStuckException') ? 'Stuck' : 'Error', e.getMessage());
		}
	}

	private void get() {
		RoutingSetting__c setting = RoutingSetting__c.getOrgDefaults();

		HttpRequest request = new HttpRequest();
		request.setEndpoint('callout:RaaS/' + jobId + '?licenseId=' + setting.Licence__c);
		request.setMethod('GET');
		request.setHeader('Content-Type', 'application/json');

		HttpResponse response = new Http().send(request);
		if (response.getStatusCode() != 200) {
			throw new RoutingException(response.getStatusCode() + ' : ' + response.getStatus() + ' : ' + response.getBody());
		}

		RoutingResponse routingResponse = (RoutingResponse) JSON.deserialize(response.getBody(), RoutingResponse.class);

		if (STATUS_IN_PROGRESS.contains(routingResponse.status)) {
			if (pollCount >= setting.MaximumPollCount__c) {
				throw new RoutingStuckException('Job did not complete. Attempts to get results exceeded allowed limit.');
			}

			enqueue();
		} else if (routingResponse.status == 'Complete') {
			processResult(routingResponse);
		} else {	// Failed
			throw new RoutingException(routingResponse.status + ' : ' + routingResponse.errorMsg);
		}
	}

	protected void resequence(List<sObject> records) {
		// Group by current sequence number
		Map<Integer, List<sObject>> recordsBySequence = new Map<Integer, List<sObject>>();
		Integer sequence;
		for (sObject record : records) {
			sequence = Convert.toInteger((Decimal)record.get('SequenceNumber__c'));
			if (recordsBySequence.containsKey(sequence)) {
				recordsBySequence.get(sequence).add(record);
			} else {
				recordsBySequence.put(sequence, new List<sObject>{record});
			}
		}

		// While maintaining the current sequence order, reassign new incremental sequence number
		List<Integer> sortedSequenceNumbers = new List<Integer>(recordsBySequence.keySet());
		sortedSequenceNumbers.sort();

		Integer incrementalSequence = 0;
		List<sObject> recordGroup;
		String recordKey;
		Map<String, Integer> keyToSequence = new Map<String, Integer>();
		Integer assignedSequence;
		for (Integer sequenceNumber : sortedSequenceNumbers) {
			recordGroup = recordsBySequence.get(sequenceNumber);
			for (sObject record : recordGroup) {
				recordKey = key(record);
				assignedSequence = keyToSequence.get(recordKey);
				if (assignedSequence == null) {
					assignedSequence = ++incrementalSequence;
					keyToSequence.put(recordKey, assignedSequence);
				}
				record.put('SequenceNumber__c', assignedSequence);
			}
		}
	}

	private class RoutingStuckException extends Exception {}
	private class RoutingException extends Exception {}
}