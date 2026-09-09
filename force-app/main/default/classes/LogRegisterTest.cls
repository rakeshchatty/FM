@isTest
private class LogRegisterTest {
    
    @isTest
    static void testLogs() {
        List<Account> accounts = new List<Account>();
        accounts.add(TestDataHelper.createAccount());
        Database.SaveResult[] resultsIns = Database.insert(accounts);
        LogRegister.createLogsUpsert(resultsIns, accounts, 'Testing', 'Insert', 'Account', null);

        Database.UpsertResult[] resultsUpd = Database.upsert(accounts);
        LogRegister.createLogsUpsert(resultsUpd, accounts, 'Testing', 'Update', 'Account', null);
        
        Database.DeleteResult[] resultsDel = Database.delete(accounts);
        LogRegister.createLogs(resultsDel, accounts, 'Testing', 'Delete', 'Account', null);        
    }

    @isTest
    static void CreateLogs() {
        
        List<Database.SaveResult> results;
        List<sObject> records;
        String process;
        String action;
        String sObjectType;
        String ParentField;
        String recordId;
        String errorMessage;
        
        List<Order> lstOrder = new List<Order>();
        
        Account novaConta = new Account(
            Name = 'TESTE Account'
        );
     
        Order Ord1 = new Order(
            AccountId = novaConta.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100
        );
        //insert ord1;
        lstOrder.add(ord1);
        
        Order Ord2 = new Order(
            AccountId = novaConta.Id,
            EffectiveDate = System.today().addMonths(-(1)),
            Delivery_Date__c = System.today().addMonths(-(1)),
            //Status = 'Confirmed',
            AD_KG__c = 100,
            Recycled_KG__c = 100,
            WTE_KG__c = 100,
            Tonnes_CO2_Saved__c = 100
        );
        lstOrder.add(ord2);

        Database.SaveResult[] resultsDB = Database.insert(lstOrder,false);
        records = lstOrder;
        process = 'LogRegister insert Order';
        action = 'Insert';
        sObjectType = 'Order';
        ParentField = '';
        
        //LogRegister.LogRegister(sObjectType, process, action, recordId, errorMessage);
        LogRegister.createLogsUpsert(resultsDB, records, process, action, sObjectType, ParentField);
        LogRegister constructor = new LogRegister('Account','Test LogResister1', 'Insert', '000000', '');
        LogRegister constructor1 = new LogRegister('Account','Test LogResister1', 'Insert', '', 'testingErros');
        List<LogRegister> logRes = new List<LogRegister>();
        logRes.add(constructor);
        logRes.add(constructor1);
        LogRegister.createLogs(logRes);

    }   
}