@istest

private class TestSplitQRCodesIntoNewRecords {
    @istest static void TestAddDetrackQRCodesRecord() {
        //test date setup
        //create new detrackQRcodesRecord
      QR_Codes_from_Detrack__c qrcodesOb = new QR_Codes_from_Detrack__c (QR_Codes_from_OrderItem__c = '12322');
      insert qrcodesOb;
        //perform test
        Test.startTest();
        qrcodesOb.Number_of_codes__c = 1;
        Test.stopTest();
    }
}