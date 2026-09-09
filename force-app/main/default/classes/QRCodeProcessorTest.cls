@isTest
public class QRCodeProcessorTest {
    
    @isTest
    public static void test(){
		
        Account parent = TestDataHelper.insertAccount();
        Account location = TestDataHelper.insertLocation(parent.Id, null);

        insert new Qr_code__c(Driver_app_QR_code__c = 'RZMa002673769', Account__c = location.Id);

        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();

        req.addHeader('httpMethod', 'POST');
        req.requestUri = '/services/apexrest/findcustomerids/'; 

        String body = '';
        body += '{';
        body += '"qrCodes" : ["RZMa002673769"]';
        body += '}';

        req.requestBody = Blob.valueof(body);
        RestContext.request = req; 
        RestContext.response= res;

        Test.startTest();
            QRCodeProcessor.findCustomerIdsByQRCodes(new List<String>{'RZMa002673769'});

            body = '';
            body += '{';
            body += '"qrCodes" : ["bdjhsb"]';
            body += '}';
            req.requestBody = Blob.valueof(body);
            RestContext.request = req; 
            RestContext.response= res;

            QRCodeProcessor.findCustomerIdsByQRCodes(new List<String>{'bdjhsb'});
        Test.stopTest();
    }
}