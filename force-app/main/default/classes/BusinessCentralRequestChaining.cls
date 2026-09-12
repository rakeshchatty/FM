public without sharing class BusinessCentralRequestChaining {

	public static final String ENTITY_ACCOUNT = 'Account';
	public static final String ENTITY_CONTACT = 'Contact';
	public static final String ENTITY_INVOICE = 'Invoice';
	public static final String ENTITY_CREDIT_NOTE = 'CreditNote';
	public static final String ENTITY_PAYMENT = 'Payment';

	private static final Integer BATCH_SIZE = LimitUtil.MAX_CALLOUTS;

	private static final Set<String> ALLOWED_STATUS = new Set<String>{'New', 'Retry'};

	private Map<String, List<Request>> entityRequestMap = new Map<String, List<Request>>();

	private static final BusinessCentralSetting__c SETTINGS = BusinessCentralSetting__c.getOrgDefaults();

	public void handleTrigger(List<BusinessCentralSendRequest__c> newList, Map<Id, BusinessCentralSendRequest__c> oldMap, TriggerOperation operation) {
		switch on operation {
			when AFTER_INSERT {
				process(newList);
			}
			when AFTER_UPDATE {
				process(newList); // retry
			}
		}
	}

	private void process(List<BusinessCentralSendRequest__c> newList) {
		for (BusinessCentralSendRequest__c request : newList) {
			if (!ALLOWED_STATUS.contains(request.Status__c)) {
				continue;
			}

			if (String.isNotBlank(request.AccountId__c) && String.isBlank(request.ContactId__c)) {
				addToMap(ENTITY_ACCOUNT, request.AccountId__c, request.Id);
				continue;
			}
			if (String.isNotBlank(request.ContactId__c)) {
				addToMap(ENTITY_CONTACT, request.AccountId__c + '-' + request.ContactId__c, request.Id);
				continue;
			}
			if (String.isNotBlank(request.InvoiceId__c)) {
				addToMap(ENTITY_INVOICE, request.InvoiceId__c, request.Id);
				continue;
			}
			if (String.isNotBlank(request.PaymentId__c)) {
				addToMap(ENTITY_PAYMENT, request.PaymentId__c, request.Id);
				continue;
			}
		}

		process();
	}

	public void process() {
		if (entityRequestMap.isEmpty()) {
			return;
		}

		if (entityRequestMap.containsKey(ENTITY_ACCOUNT) && SETTINGS.SendAccount__c) {
			Database.executeBatch(new BusinessCentralSendAccountBatch(this), BATCH_SIZE);
			return;
		}

		if (entityRequestMap.containsKey(ENTITY_CONTACT) && SETTINGS.SendAccount__c) {
			Database.executeBatch(new BusinessCentralSendContactBatch(this), BATCH_SIZE);
			return;
		}

		if (entityRequestMap.containsKey(ENTITY_INVOICE) && SETTINGS.SendInvoice__c) {
			Database.executeBatch(new BusinessCentralSendInvoiceBatch(this), 1);
			return;
		}

		if (entityRequestMap.containsKey(ENTITY_PAYMENT) && SETTINGS.SendPayment__c) {
			Database.executeBatch(new BusinessCentralSendPaymentBatch(this), 10);
			return;
		}
	}

	public Map<String, Id> getRequests(String entityName) {
		Map<String, Id> objectToRequestMap = new Map<String, Id>();
		for (Request request : entityRequestMap.get(entityName)) {
			objectToRequestMap.put(request.key, request.queueId);
		}

		entityRequestMap.remove(entityName);
		return objectToRequestMap;
	}

	private void addToMap(String entityName, String key, Id queueId) {
		if (!entityRequestMap.containsKey(entityName)) {
			entityRequestMap.put(entityName, new List<Request>());
		}
		entityRequestMap.get(entityName).add(new Request(key, queueId));
	}

	private class Request {
		private String key;
		private Id queueId;

		private Request(String key, Id queueId) {
			this.key = key;
			this.queueId = queueId;
		}
	}
}