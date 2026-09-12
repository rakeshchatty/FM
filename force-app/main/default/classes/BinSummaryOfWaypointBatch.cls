public without sharing class BinSummaryOfWaypointBatch implements Database.Batchable<sObject>, Database.Stateful {

	private String MONTH;
	private String YEAR;
	private String CREATED_DATE_CRITERIA;

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Date today = System.today();

		if (today.day() == 1) {
			Date yesterday = today - 1;
			CREATED_DATE_CRITERIA = 'CreatedDate = LAST_MONTH';
			MONTH = String.valueOf('0' + yesterday.month()).right(2);
			YEAR = String.valueOf(yesterday.year());
		} else {
			CREATED_DATE_CRITERIA = 'CreatedDate = THIS_MONTH AND CreatedDate != TODAY';
			MONTH = String.valueOf('0' + today.month()).right(2);
			YEAR = String.valueOf(today.year());
		}

		String query = 'SELECT Id FROM Account WHERE Id IN (SELECT Location__c FROM Collection_Waypoints__c WHERE BinKey__c != null AND ' + CREATED_DATE_CRITERIA + ')';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> locations) {
		List<BinSummary__c> binSummaries = new List<BinSummary__c>();
		String key;
		List<String> splitKey;

		String aggregateQuery = 'SELECT BinKey__c, SUM(Collection_Quantity__c) Waypoints FROM Collection_Waypoints__c WHERE Location__c IN :locations AND BinKey__c != null AND ' + CREATED_DATE_CRITERIA + ' GROUP BY BinKey__c';
		for (AggregateResult aggregateResult : Database.query(aggregateQuery)) {
			key = (String)aggregateResult.get('BinKey__c');
			splitKey = StringUtil.splitTrim(key, '-');
			binSummaries.add(new BinSummary__c(Key__c = key, Location__c = splitKey[0], CategoryCode__c = splitKey[1], Year__c = YEAR, Month__c = MONTH, Waypoints__c = (Decimal)aggregateResult.get('Waypoints')));
		}

		if (!binSummaries.isEmpty()) {
			UPSERT binSummaries Key__c;
		}
	}

	public void finish(Database.BatchableContext BC) {
		Database.executeBatch(new BinSummaryOfOrderProductBatch());
	}
}