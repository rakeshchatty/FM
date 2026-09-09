@isTest
public class SendgridHelper_Test
{
    public static testmethod void SendgridHelperlocationContactv1()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV1());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        con.Unsubscribed__c = true;
        update con;
        
        con.Unsubscribed__c = false;
        update con;
        
        delete con;
        Test.StopTest();
    }
    public static testmethod void SendgridHelperlocationContactv2()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        con.Unsubscribed__c = true;
        update con;
        
        con.Unsubscribed__c = false;
        update con; 
        Test.StopTest();
    }
    public static testmethod void SendgridHelperlocationContactv3()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV2());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        con.FMCP_Token__c = '123dfres';
        update con;
        
        con.Email = 'test@d.com';
        update con;
        
        delete con;
        Test.StopTest();
    }
    public static testmethod void SendgridHelperlocationContactv4()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV2());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        con.FMCP_Token__c = '123dfres';
        update con;
        
        acc.ParentId = null;
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        acc.InvoiceFrequency__c = 'Monthly';
        update acc;
        
        acc.RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Account').getRecordTypeId();
        update acc;
        
        acc.Enqix_Dead_Live__c = 'Dead';
        update acc;
        
        Test.StopTest();
    }
    public static testmethod void SendgridHelperlocationContactv5()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV2());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;  
        
        acc.Name = '123test';
        update acc;
        
        Test.StopTest();
    }
    public static testmethod void SendgridHelperlocationContactv6()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV2());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.createLocation(parent.Id, null);
        acc.Enqix_Dead_Live__c = 'Dead';
        acc.Enqix_ReasonMarkedDead__c = 'Giveaway Never Ordered';
        INSERT acc;
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;        
        Test.StopTest();
    }
    public static testmethod void SendgridHelperaccountContactv1()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV1());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        con.FirstName = 'testv1';
        update con;
        
        con.Unsubscribed__c = true;
        update con;
                
        con.Unsubscribed__c = false;
        update con;
        
        delete con;
        Test.StopTest();
    }
    public static testmethod void SendgridHelperaccountContactv2()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMock());
        Test.startTest();
        Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.insertLocation(parent.Id, null);
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;
        
        con.FirstName = 'testv1';
        update con;
        
        con.Unsubscribed__c = false;
        update con; 
        Test.StopTest();
    }
    public static testmethod void SendgridHelperaccountContactv3()
    { 
        Sendgrid_Setting__c objsg = UnitTest.testsgsetting();
        insert objsg;
        Test.setMock(HttpCalloutMock.class, new RestMockV2());
        Test.startTest();
       Account parent = TestDataHelper.insertAccount();
        Account acc = TestDataHelper.createLocation(parent.Id, null);
        acc.Enqix_Dead_Live__c = 'Dead';
        acc.Enqix_ReasonMarkedDead__c = 'Giveaway Never Ordered';
        INSERT acc;
        
        Contact con = UnitTest.testcontact(acc.Id);
        insert con;  
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
    
    private class RestMockV1 implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"result":[{"address_line_1":"","address_line_2":"","alternate_emails":null,"city":"","country":"","email":"test@de.com","first_name":"Heena","id":"59582f83-86d4-42f8-8997-16a5d77229a6","last_name":"Gauswami","list_ids":["f4a75679-2842-462f-9e52-a2024065e126","bff14abf-91c6-44c9-b3d5-d2293566f3a3"],"postal_code":"","state_province_region":"","phone_number":"","whatsapp":"","line":"","facebook":"","unique_name":"","_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contact/59582f83-86d4-42f8-8997-16a5d77229a6"},"custom_fields":{"AccountName":"Synoptek","CPToken":"4587123654","ContactId":"00Qw0000017ps8U"},"created_at":"2020-07-14T12:07:54Z","updated_at":"2020-07-16T11:51:30.758554952Z"},{"address_line_1":"","address_line_2":"","alternate_emails":null,"city":"","country":"","email":"hiren_goswami123@yahoo.com","first_name":"hiren","id":"389a21c0-d595-47ff-807d-6d1b0f4497b1","last_name":"Gauswami","list_ids":["bff14abf-91c6-44c9-b3d5-d2293566f3a3"],"postal_code":"","state_province_region":"","phone_number":"","whatsapp":"","line":"","facebook":"","unique_name":"","_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contact/389a21c0-d595-47ff-807d-6d1b0f4497b1"},"custom_fields":{},"created_at":"2020-07-19T09:12:23Z","updated_at":"2020-07-19T09:12:24.133456501Z"},{"address_line_1":"","address_line_2":"","alternate_emails":null,"city":"","country":"","email":"sonani_heena123@yahoo.in","first_name":"Heena","id":"f099036b-3660-42dd-a8f2-5ea5ee6c2ab3","last_name":"Sonani","list_ids":["f4a75679-2842-462f-9e52-a2024065e126"],"postal_code":"","state_province_region":"","phone_number":"","whatsapp":"","line":"","facebook":"","unique_name":"","_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contact/f099036b-3660-42dd-a8f2-5ea5ee6c2ab3"},"custom_fields":{},"created_at":"2020-07-16T11:51:30Z","updated_at":"2020-07-16T11:51:30.759305535Z"}],"contact_count":3,"_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contacts"}}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
    private class RestMockV2 implements HttpCalloutMock {
        
        public HTTPResponse respond(HTTPRequest req) {
            String fullJson = '{"result":[{"address_line_1":"","address_line_2":"","alternate_emails":null,"city":"","country":"","email":"test@d.com","first_name":"Heena","id":"59582f83-86d4-42f8-8997-16a5d77229a6","last_name":"Gauswami","list_ids":["f4a75679-2842-462f-9e52-a2024065e126","bff14abf-91c6-44c9-b3d5-d2293566f3a3"],"postal_code":"","state_province_region":"","phone_number":"","whatsapp":"","line":"","facebook":"","unique_name":"","_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contact/59582f83-86d4-42f8-8997-16a5d77229a6"},"custom_fields":{"AccountName":"Synoptek","CPToken":"4587123654","ContactId":"00Qw0000017ps8U"},"created_at":"2020-07-14T12:07:54Z","updated_at":"2020-07-16T11:51:30.758554952Z"},{"address_line_1":"","address_line_2":"","alternate_emails":null,"city":"","country":"","email":"hiren_goswami123@yahoo.com","first_name":"hiren","id":"389a21c0-d595-47ff-807d-6d1b0f4497b1","last_name":"Gauswami","list_ids":["bff14abf-91c6-44c9-b3d5-d2293566f3a3"],"postal_code":"","state_province_region":"","phone_number":"","whatsapp":"","line":"","facebook":"","unique_name":"","_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contact/389a21c0-d595-47ff-807d-6d1b0f4497b1"},"custom_fields":{},"created_at":"2020-07-19T09:12:23Z","updated_at":"2020-07-19T09:12:24.133456501Z"},{"address_line_1":"","address_line_2":"","alternate_emails":null,"city":"","country":"","email":"sonani_heena123@yahoo.in","first_name":"Heena","id":"f099036b-3660-42dd-a8f2-5ea5ee6c2ab3","last_name":"Sonani","list_ids":["f4a75679-2842-462f-9e52-a2024065e126"],"postal_code":"","state_province_region":"","phone_number":"","whatsapp":"","line":"","facebook":"","unique_name":"","_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contact/f099036b-3660-42dd-a8f2-5ea5ee6c2ab3"},"custom_fields":{},"created_at":"2020-07-16T11:51:30Z","updated_at":"2020-07-16T11:51:30.759305535Z"}],"contact_count":3,"_metadata":{"self":"https://api.sendgrid.com/v3/marketing/contacts"}}';
            HTTPResponse res = new HTTPResponse();
            res.setHeader('Content-Type', 'text/json');
            res.setBody(fullJson);
            res.setStatusCode(200);
            return res;
        }
    }
}