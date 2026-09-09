@isTest
private class BankStatements_Test {
    
    @future
    private static void insertCustomSetting(){
        Enqix_Id_automation__c testRecord = new Enqix_Id_automation__c(Name = 'teste', Enqix_id__c = 20000, Enqix_Location_Id__c = 30000);
        system.debug('DEBUG========================='+testRecord);
        insert testRecord;
    } 
      
    @testSetup
    static void setup() {
        TestDataHelper.insertVat();
    }

    @isTest 
    static void test_method_one() {
            
        Account a = new Account();
        a.Name = 'test account';
        a.BACS_Account_Number__c = 'D 000000';
        a.BACS_Sort_Code__c = 'UK LIMIT';
        a.Enqix_Id__c = '12345y';
        a.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        insert a;
        
        List<Invoice_Header__c> invoicesToTest = new List<Invoice_Header__c>();

        Invoice_Header__c SpecificHeader1 = new Invoice_Header__c();
        SpecificHeader1.Name = 'test specific invoice header 1';
        SpecificHeader1.Account__c = a.Id;
        SpecificHeader1.AmountOutstanding__c = 150;
        SpecificHeader1.Salesforce__c = true;
        SpecificHeader1.InvoiceFrequency__c = 'Per Order';
        SpecificHeader1.VAT__c = 50;
        Insert SpecificHeader1;

        Invoice_Header__c ih2 = new Invoice_Header__c();
        ih2.Name = 'test invoice header 2';
        ih2.Account__c = a.Id;
        ih2.AmountOutstanding__c = 250;
        ih2.Salesforce__c = true;
        ih2.Original_Invoice_to_Credit__c = SpecificHeader1.Id;
        ih2.VAT__c = 50;
        ih2.InvoiceFrequency__c = 'Per Order';
        invoicesToTest.add(ih2);
        
        Invoice_Header__c ih3 = new Invoice_Header__c(); 
        ih3.Name = 'test invoice header 2';
        ih3.Account__c = a.Id;
        ih3.AmountOutstanding__c = -10;
        ih3.Original_Invoice_to_Credit__c = SpecificHeader1.Id;
        ih3.Salesforce__c = true;
        ih3.VAT__c = 1.2;
        ih3.InvoiceFrequency__c = 'Per Order';
         invoicesToTest.add(ih3);
        
        insert invoicesToTest;
        
        Invoice_Header__c invocieToSpecifiicPayment;
        
        invocieToSpecifiicPayment = [SELECT Id FROM Invoice_Header__c WHERE Name LIKE 'test specific invoice%' LIMIT 1];

        List<Bank_Statement__c> bsToInsert = new List<Bank_Statement__c>();
        
        test.startTest();

        Bank_Statement__c BSForSpecificIncoice = new Bank_Statement__c();
        BSForSpecificIncoice.Transaction_Details__c = 'Pay account specific invoices';
        BSForSpecificIncoice.Cancelled__c = false;
        BSForSpecificIncoice.Unallocated_Amount__c = 75;
        BSForSpecificIncoice.Account__c = a.Id;
        BSForSpecificIncoice.CP_Transactional_Info__c = 'cp_testspecificpayment00001';
        BSForSpecificIncoice.Entry_Date__c = System.today();
        BSForSpecificIncoice.Transaction_Type__c = 'Credit Card';
        BSForSpecificIncoice.Document_name__c = 'Charge for ['+ invocieToSpecifiicPayment.Id + ', ' + invocieToSpecifiicPayment.Id + ']';
        BSForSpecificIncoice.Receipt_Amount__c = 75;
        BSForSpecificIncoice.Credit_Note_Invoice__c = ih3.Id;
        //insert BSForSpecificIncoice; 
        bsToInsert.add(BSForSpecificIncoice);

        SpecificHeader1.Query__c = false;
        SpecificHeader1.Status__c = 'Draft';
		SpecificHeader1.AmountOutstanding__c = 10;
        update SpecificHeader1;
        ih2.Original_Invoice_to_Credit__c = [Select Id From Invoice_Header__c Where Name = :SpecificHeader1.Name LIMIT 1].Id;
        ih2.AmountOutstanding__c = -10;
        update ih2;
        
        Bank_Statement__c bs = new Bank_Statement__c();
        bs.Transaction_Details__c = 'ZARA UK LIMITED 00000002';
        bs.Cancelled__c = false;
        bs.Unallocated_Amount__c = 205;
        bs.Account__c = a.Id;
        bs.Entry_Date__c = System.today();
        bs.Transaction_Type__c = 'Bank Giro Credit';
        bs.Document_name__c = 'test bss';
        bs.Receipt_Amount__c = 20;
        bs.Credit_Note_Invoice__c = ih3.Id;
        bs.MarkedForSage__c  = true;
        bsToInsert.add(bs);
            
        
        Bank_Statement__c bs3 = new Bank_Statement__c();
        bs3.Transaction_Details__c = 'ZARA UK LIMITED 00000002';
        bs3.Cancelled__c = false;
        bs3.Unallocated_Amount__c = 205;
        bs3.Account__c = a.Id;
        bs3.Entry_Date__c = System.today();
        bs3.Transaction_Type__c = 'Credit Note';
        bs3.Document_name__c = 'test bss';
        bs3.Receipt_Amount__c = 205;
        bs3.Credit_Note_Invoice__c = ih3.Id;
        bs3.MarkedForSage__c  = true;
        bsToInsert.add(bs3);
        
        Bank_Statement__c feeBS = new Bank_Statement__c();
        feeBS.Transaction_Details__c = 'ZARA UK LIMITED 00000002';
        feeBS.RecordTypeId = Schema.SObjectType.Bank_Statement__c.getRecordTypeInfosByName().get('Fee').getRecordTypeId();
        feeBS.Cancelled__c = false;
        feeBS.Unallocated_Amount__c = 205;
        feeBS.Account__c = a.Id;
        feeBS.Entry_Date__c = System.today();
        feeBS.Transaction_Type__c = 'Bank Giro Credit';
        feeBS.Document_name__c = 'test bss';
        feeBS.Receipt_Amount__c = 20;
        feeBS.Credit_Note_Invoice__c = ih3.Id;
        feeBS.MarkedForSage__c  = true;
        bsToInsert.add(feeBS);

        insert bsToInsert;
        
        test.stopTest();
        
        PaymentAllocation__c pa = new PaymentAllocation__c();
        pa.InvoiceId__c = ih2.Id;
        pa.BankstatementId__c = bs3.Id;
        pa.AllocatedAmount__c = 10;
        pa.Account__c = a.Id;
        pa.Automatic_Payment__c = false;
        pa.IsCreditNote__c = true;
        pa.IsDirectDebit__c = true;
        pa.IsFromCPCard__c = true;
        insert pa;
  
        //bs.Transaction_Type__c = 'Direct Debit';
        bs.Cancelled__c = true;
        bs3.Transaction_Type__c = 'Direct Debit';
        bs3.Unallocated_Amount__c = 250;

        update bs; 
        delete bs3;
    }  
}