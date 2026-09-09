@isTest
private class SageCsvFileControllerTest {

    @isTest
    static void test() {

        List < SageExtract__c > lstSages = new List < SageExtract__c > ();

        SageExtract__c novoSage = new SageExtract__c(
            Name = 'TESTE Sage',
            DatePostedtoSage__c = system.today(),
            AccountNumber__c = '1100',
            GoodsAmount__c = 400,
            TransactionDate__c = system.today(),
            PostedtoSage__c = false
        );
        
        SageExtract__c novoSage1 = new SageExtract__c(
            Name = 'TESTE Sage1',
            DatePostedtoSage__c = system.today(),
            AccountNumber__c = '1200',
            GoodsAmount__c = 500,
            TransactionDate__c = system.today(),
            PostedtoSage__c = false
        );
        lstSages.add(novoSage);
        lstSages.add(novoSage1);
        insert lstSages;
        
		//Cover PageReference Method
        PageReference pageRef = Page.SageCSV;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id',novoSage.id);     
        ApexPages.StandardSetController stc = new ApexPages.StandardSetController(lstSages);
        SageCsvFileController objCtrl = new SageCsvFileController(stc);
        PageReference objPageRef = objCtrl.newPage();
        
        objCtrl.SageCSVFileBatchMethod();
        objCtrl.spin();
        
        System.assertEquals(2, objCtrl.sageFiles.getRecords().size());

    }
    
}