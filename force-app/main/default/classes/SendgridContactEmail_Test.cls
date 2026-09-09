@isTest
public class SendgridContactEmail_Test
{
    public static testmethod void SendGridSendEmailV1()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        Case reccase = UnitTest.testcase(acc.Id, con.Id);
        insert reccase;
        SendGridSendEmail sendemail = new SendGridSendEmail();
        
        SendGridSendEmail.ContactemailParameter param = new SendGridSendEmail.ContactemailParameter();
        param.templateId = '';
        param.contactName = con.Name;
        param.contactEmail = con.Email;
        param.cpToken = 'tttt';
        param.accountName = acc.Name;
        param.parentAccountName = 'tttt';
        param.outstandingBalance = 'tttt';
        param.orderNumber = 'tttt'; 
        
        SendGridSendEmail.ContactemailParameter[] lst = new SendGridSendEmail.ContactemailParameter[]{param};
        //lst.add(param);
        
        SendGridSendEmail.EmailtoContact(lst);
        Test.StopTest();
    }
    public static testmethod void SendGridSendEmailV2()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Account acc1 = TestDataHelper.createLocation(parent.Id, null);
        acc1.Name = 'location 2';
        INSERT acc1;
        
        Contact con = UnitTest.testcontact(acc.Id);
        con.Email = 'test@sts1.com';
        insert con;
        
        Contact con1 = UnitTest.testcontact(acc.Id);
        con1.Email = 'test@sts2.com';
        insert con1;
        
        Contact con3 = UnitTest.testcontact(acc.Id);
        con3.Email = 'test@sts3.com';
        insert con3;
        
        List<AccountContactRelation> lstacr = new List<AccountContactRelation>();
        AccountContactRelation acr1 = UnitTest.testAccConRelation(acc1.Id,con.Id, 'Service Contact');
        AccountContactRelation acr2 = UnitTest.testAccConRelation(acc1.Id,con1.Id, 'Service Contact');
        AccountContactRelation acr3 = UnitTest.testAccConRelation(acc1.Id,con3.Id, 'Finance Contact');
        lstacr.add(acr1);
        lstacr.add(acr2);
        lstacr.add(acr3); 
        Insert lstacr;
        
        Case reccase = UnitTest.testcase(acc.Id, con.Id);
        insert reccase;
        SendGridSendServiceFinanceContactEmail sendemail = new SendGridSendServiceFinanceContactEmail();
        
        SendGridSendServiceFinanceContactEmail.ServiceFinanceContactemailParameter param = new SendGridSendServiceFinanceContactEmail.ServiceFinanceContactemailParameter();
        param.templateId = '';
        param.role = 'Service Contact'; 
        param.accountId = acc1.Id; 
        param.accountName = acc.Name;
        param.parentAccountName = 'tttt';
        param.outstandingBalance = 'tttt';
        param.orderNumber = 'tttt'; 
        
        SendGridSendServiceFinanceContactEmail.ServiceFinanceContactemailParameter[] lst = new SendGridSendServiceFinanceContactEmail.ServiceFinanceContactemailParameter[]{param};
  
        SendGridSendServiceFinanceContactEmail.EmailtoServicefinanceContact(lst);
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