public without sharing class DeleteSObjectBatch implements Database.Batchable<sObject> {

	private string query;
	public DeleteSObjectBatch(String query) {
		this.query = query;
	}

	public Database.QueryLocator start(Database.BatchableContext BC) {
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext BC, List<SObject> scope) {
		Database.delete(scope, false);
	}

	public void finish(Database.BatchableContext BC) {}
}