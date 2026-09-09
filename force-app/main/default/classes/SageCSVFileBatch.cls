public class SageCSVFileBatch implements Database.Batchable<sObject>, Database.Stateful {

	private SageExtractFile__c sageExtractFile;

	public SageCSVFileBatch(Id sageExtractFileId) {
		sageExtractFile = [SELECT Id, Name FROM SageExtractFile__c WHERE Id = :sageExtractFileId];
	}

	public Database.QueryLocator start(Database.BatchableContext batchContext) {
		String query = 'SELECT Id, Name, Narrative__c, DatePostedtoSage__c, AccountNumber__c, GoodsAmount__c, TransactionDate__c, PostedtoSage__c, Bank_Statement__c, Bank_Statement__r.Id, Invoice_Line__c, Invoice_Line__r.Id, CreatedDate FROM SageExtract__c WHERE PostedtoSage__c = false AND TransactionDate__c != null ORDER BY Bank_Statement__c, Invoice_Line__c, CreatedDate';
		return Database.getQueryLocator(query);
	}

	public void execute(Database.BatchableContext batchContext, List<SageExtract__c> sageExtracts) {
		for (SageExtract__c sageExtract : sageExtracts) {
			sageExtract.PostedtoSage__c = true;
			sageExtract.DatePostedtoSage__c = System.today();
			sageExtract.SageExtractFile__c = sageExtractFile.Id;
			sageExtract.Narrative__c = sageExtractFile.Name;
		}
		UPDATE sageExtracts;
	}

	public void finish(Database.BatchableContext batchContext) {}
}