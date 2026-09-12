public without sharing class BinSummaryOfOrderProductBatch implements Database.Batchable<sObject>, Database.Stateful {

	private String MONTH;
	private String YEAR;
	private String CREATED_DATE_CRITERIA;

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Date today = System.today();

		if (today.day() == 1) {
			Date yesterday = today - 1;
			CREATED_DATE_CRITERIA = 'CollectionDate__c = LAST_MONTH';
			MONTH = String.valueOf('0' + yesterday.month()).right(2);
			YEAR = String.valueOf(yesterday.year());
		} else {
			CREATED_DATE_CRITERIA = 'CollectionDate__c = THIS_MONTH AND CollectionDate__c != TODAY';
			MONTH = String.valueOf('0' + today.month()).right(2);
			YEAR = String.valueOf(today.year());
		}

		String query = 'SELECT Id FROM Account WHERE Id IN (SELECT Location__c FROM OrderItem WHERE BinKey__c != null AND ' + CREATED_DATE_CRITERIA + ')';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> locations) {
		List<BinSummary__c> binSummaries = new List<BinSummary__c>();
		String key;
		List<String> splitKey;

		String aggregateQuery = 'SELECT BinKey__c, SUM(Quantity) OrderProducts FROM OrderItem WHERE Location__c IN :locations AND BinKey__c != null AND ' + CREATED_DATE_CRITERIA + ' GROUP BY BinKey__c';
		for (AggregateResult aggregateResult : Database.query(aggregateQuery)) {
			key = (String)aggregateResult.get('BinKey__c');
			splitKey = StringUtil.splitTrim(key, '-');
			binSummaries.add(new BinSummary__c(Key__c = key, Location__c = splitKey[0], CategoryCode__c = splitKey[1], Year__c = YEAR, Month__c = MONTH, OrderProducts__c = (Decimal)aggregateResult.get('OrderProducts')));
		}

		if (!binSummaries.isEmpty()) {
			UPSERT binSummaries Key__c;
		}
	}

	public void finish(Database.BatchableContext BC) {
        Database.executeBatch(new BinSummaryOfBinLiftBatch());
    }
}