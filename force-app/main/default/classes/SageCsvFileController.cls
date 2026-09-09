public with sharing class SageCsvFileController {

	public ApexPages.StandardSetController sageFiles {
		get {
			if (sageFiles == null) {
				sageFiles = new ApexPages.StandardSetController(Database.getQueryLocator(
					[Select Id, Name, DatePostedtoSage__c, AccountNumber__c, GoodsAmount__c, TransactionDate__c, PostedtoSage__c FROM SageExtract__c WHERE PostedtoSage__c = false]));
				sageFiles.setPageSize(sageFiles.getResultSize());
			}
			return sageFiles;
		}
		set;
	}

	public SageCsvFileController(ApexPages.StandardSetController ctrl) {}

	public void spin() {
		long now = datetime.now().gettime();
		while(datetime.now().gettime()-now<5000); // Busy loop for 5000 ms
	}

	public void SageCSVFileBatchMethod() {
		SageExtractFile__c sef = new SageExtractFile__c();
		INSERT sef;
		Database.executeBatch(new SageCSVFileBatch(sef.Id), 2000);
	}

	public PageReference newPage() {
		PageReference retURL = new PageReference('/lightning/o/SageExtractFile__c/list?filterName=Recent');
		system.debug(retURL);
		retURL.setRedirect(true);
		return retURL;
	}
}