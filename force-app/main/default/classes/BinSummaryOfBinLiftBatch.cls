public without sharing class BinSummaryOfBinLiftBatch implements Database.Batchable<sObject>, Database.Stateful {

	private String MONTH;
	private String YEAR;
	private String DATE_CRITERIA;

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		Date today = System.today();

		if (today.day() == 1) {
			Date yesterday = today - 1;
			DATE_CRITERIA = 'CollectedAt__c = LAST_MONTH';
			MONTH = String.valueOf('0' + yesterday.month()).right(2);
			YEAR = String.valueOf(yesterday.year());
		} else {
			DATE_CRITERIA = 'CollectedAt__c = THIS_MONTH AND CollectedAt__c != TODAY';
			MONTH = String.valueOf('0' + today.month()).right(2);
			YEAR = String.valueOf(today.year());
		}

		String query = 'SELECT Id FROM Account WHERE Id IN (SELECT Location__c FROM BinLift__c WHERE Status__c IN (\'No match\', \'Matched\', \'Weight Added\') AND ' + DATE_CRITERIA + ')';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<Account> locations) {
		Map<String, BinSummary__c> binSummaryMap = new Map<String, BinSummary__c>();
		String status;
		String key;
		List<String> splitKey;

		String aggregateQuery = 'SELECT Key__c, Status__c, Count(Id) BinLifts, SUM(Overweight__c) OverWeight FROM BinLift__c WHERE Location__c IN :locations AND Status__c IN (\'No match\', \'Matched\', \'Weight Added\') AND ' + DATE_CRITERIA
			+ ' GROUP BY Key__c, Status__c';
		for (AggregateResult aggregateResult : Database.query(aggregateQuery)) {
			status = (String)aggregateResult.get('Status__c');
			key = (String)aggregateResult.get('Key__c');
			splitKey = StringUtil.splitTrim(key, '-');
			BinSummary__c binSummary;

			if (binSummaryMap.containsKey(key)) {
				binSummary = binSummaryMap.get(key);
			} else {
				binSummary = new BinSummary__c(Key__c = key, Location__c = splitKey[0], CategoryCode__c = splitKey[1], Year__c = YEAR, Month__c = MONTH);
			}
			if (status == 'No match') {
				binSummary.BinUnmatched__c = (Integer)aggregateResult.get('BinLifts');
				binSummary.BinUnmatchedOverweight__c = (Decimal)aggregateResult.get('OverWeight');
			} else if (status == 'Matched' || status == 'Weight Added') {
				binSummary.BinMatched__c = (Integer)aggregateResult.get('BinLifts');
			}
			binSummaryMap.put(key, binSummary);
		}

		if (!binSummaryMap.isEmpty()) {
			UPSERT binSummaryMap.values() Key__c;
		}
	}

	public void finish(Database.BatchableContext BC) {
		// if (System.today().day() == 1) {
		// 	Database.executeBatch(new BinChargeBatch(), 50);
		// }
	}
}