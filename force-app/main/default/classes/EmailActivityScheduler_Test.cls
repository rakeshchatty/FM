@isTest
public class EmailActivityScheduler_Test
{
    public static testmethod void EmailActivityrun()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        
        Account acc = TestDataHelper.insertAccount();
        
        Contact con = UnitTest.testcontact(acc.Id);
        con.Email = 'customers@thefirstmile.co.uk';
        insert con;
        
        con = UnitTest.testcontact(acc.Id);
        con.Email = 'meatvillageltd@gmail.com';
        insert con;
        
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        EmailActivityScheduler myClass = new EmailActivityScheduler();   
        String chron = '0 0 23 * * ?';        
        system.schedule('Test Sched', chron, myClass);
        Test.StopTest();
    }
    private class RestMock implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"messages":[{"from_email":"customers@thefirstmile.co.uk","msg_id":"98vYcmLlQDWes-JaJva_rw.filterdrecv-p3mdw1-75c584b9c6-q6br2-18-5F1A55BA-3A.0","subject":"New Compliance Document","to_email":"meatvillageltd@gmail.com","status":"delivered","opens_count":3,"clicks_count":2,"last_event_time":"2020-07-26T16:46:20Z"}]}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}