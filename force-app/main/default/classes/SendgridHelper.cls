//Test class - SendgridHelper_Test
public class SendgridHelper
{
    @future(callout=true)
    public static void UpsertContactList(Set<Id> locationcontactIds, Set<Id> accountcontactIds, Set<Id> AccountIds)    
    {
        if((locationcontactIds != null && locationcontactIds.size() > 0) || (accountcontactIds != null && accountcontactIds.size() > 0))
        {
            Set<Id> conIds = new Set<id>();
            List<Contact> locationcontacts = new list<Contact>();
            List<Contact> accountcontacts = new list<Contact>();
            Map<Id, Account> mapAccounts = new Map<Id, Account>();
            if(AccountIds != null)
            {
                mapAccounts = new Map<Id, Account>([Select Id, Name, RecordTypeId, RecordType.Name, Enqix_Dead_Live__c from Account where Id =: AccountIds ]);
            }
            if(locationcontactIds != null)
            {
                conIds.addall(locationcontactIds);
            }
            if(accountcontactIds != null)
            {
                conIds.addall(accountcontactIds);
            }
            Map<Id, Contact> mapcontacts = new Map<Id, Contact>([Select Id, AccountId, Name, Email, FirstName, Lastname, FMCP_Token__c  from Contact where Id = : conIds]);
            for(Contact c : mapcontacts.values())
            {
                if(locationcontactIds != null && locationcontactIds.Contains(c.Id))
                {
                    locationcontacts.add(c);
                }   
                if(accountcontactIds != null && accountcontactIds.Contains(c.Id))
                {
                    accountcontacts.add(c);
                }
            } 
            
            string locationlistId = '';
            string accountlistId = '';
            string apiKey = '';
            Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
            if(objsg != null)
            {
                locationlistId = objsg.Location_Contact_Sendgrid_Id__c;
                accountlistId = objsg.Account_Contact_Sendgrid_Id__c;
                apiKey = objsg.Integration_API_Key__c; 
                
                if(locationcontacts != null && locationcontacts.size() > 0)
                {
                    List<SG_Contact> lstlocationdata = new List<SG_Contact>();
                    for(Contact con : locationcontacts)
                    {
                        SG_Contact sg = new SG_Contact();
                        sg.email = con.Email;
                        if(con.FirstName != null)
                            sg.first_name = con.FirstName;
                        sg.last_name = con.LastName;
                        CustomFieldIds custom_fields = new CustomFieldIds();
                        custom_fields.e1_T = '';
                        custom_fields.e2_T = '';
                        if(con.FMCP_Token__c != null)
                            custom_fields.e1_T = con.FMCP_Token__c ;
                        if(mapAccounts != null && mapAccounts.containsKey(con.AccountId))
                        {
                            custom_fields.e2_T = mapAccounts.get(con.AccountId).Name;
                        }
                        custom_fields.e3_T = con.Id;
                        sg.custom_fields = custom_fields ;
                        lstlocationdata.add(sg); 
                    }
                    if(lstlocationdata != null && lstlocationdata.size() > 0)
                    { 
                        List<string> strlocation = new List<string>();
                        strlocation.add(locationlistId);
                        SG_UpsertContact obj = new SG_UpsertContact();
                        obj.list_ids = strlocation;                    
                        obj.contacts = lstlocationdata ;
                        string data = JSON.serialize(obj);                    
                        SendgridUpsertContacts(objsg, data);
                    }
                }
                if(Accountcontacts != null && Accountcontacts.size() > 0)
                {
                    List<SG_Contact> lstAccountdata = new List<SG_Contact>();
                    for(Contact con : Accountcontacts)
                    {
                        SG_Contact sg = new SG_Contact();
                        sg.email = con.Email;
                        sg.first_name = con.FirstName;
                        sg.last_name = con.LastName;
                        CustomFieldIds custom_fields = new CustomFieldIds();
                        custom_fields.e1_T = '';
                        custom_fields.e2_T = '';
                        if(con.FMCP_Token__c != null)
                            custom_fields.e1_T = con.FMCP_Token__c ;
                        if(mapAccounts != null && mapAccounts.containsKey(con.AccountId))
                        {
                            custom_fields.e2_T = mapAccounts.get(con.AccountId).Name;
                        }
                        custom_fields.e3_T = con.Id;
                        sg.custom_fields = custom_fields ;
                        lstAccountdata.add(sg); 
                    }
                    if(lstAccountdata != null && lstAccountdata.size() > 0)
                    { 
                        List<string> straccount = new List<string>();
                        straccount.add(accountlistId );
                        SG_UpsertContact obj = new SG_UpsertContact();
                        obj.list_ids = straccount ;                    
                        obj.contacts = lstAccountdata ;
                        string data = JSON.serialize(obj);                    
                        SendgridUpsertContacts(objsg, data);
                    }
                }
            }
        }
    }
    @future (callout=true)
    public static void RemoveContactfromList(Set<String> locationemails, Set<String> accountemails, Set<string> deletecontactemails) 
    {
        if((locationemails != null && locationemails.size() > 0) || (accountemails != null && accountemails.size() > 0) || ((deletecontactemails != null && deletecontactemails.size() > 0)))
        {
            system.debug('locationemails **'+locationemails );
            system.debug('accountemails **'+accountemails);
             List<SendgridContact> lstSGAllcontacts = new List<SendgridContact>();
             lstSGAllcontacts = SendgridGetContacts(); 
             if(lstSGAllcontacts != null && lstSGAllcontacts.size() > 0)
             {
                 Map<string, SendgridContact> mapemailcons = new map<string, SendgridContact>(); 
                 for(SendgridContact sgc : lstSGAllcontacts)
                 {
                     mapemailcons.put(sgc.email, sgc);
                 }
                 List<SendgridContact> lstSGcontacts = new List<SendgridContact>();        
                 Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
                 string locationlistId = '';
                 string accountlistId = '';
                 if(objsg != null)
                 {
                     locationlistId = objsg.Location_Contact_Sendgrid_Id__c;
                     accountlistId = objsg.Account_Contact_Sendgrid_Id__c;
                 }
                 
                 string removeids = '';
                 if(locationemails != null && locationemails.size() > 0)
                 {
                     for(string email : locationemails)
                     { 
                         //if email is exist in sendgrd list then remove...
                         if(mapemailcons.containsKey(email))
                         {
                             SendgridContact sgc = mapemailcons.get(email);
                             List<string> list_ids = new List<string>();
                             list_ids = sgc.list_ids;
                             system.debug('list_ids**'+list_ids);
                             if(list_ids != null && list_ids.size() > 0 && list_ids.contains(locationlistId))
                             { 
                                 //remove Contact from list 
                                 if(!removeids.Contains(sgc.id + ','))
                                     removeids = removeids + sgc.id + ','; 
                             }
                         }
                     }
                     if(removeids != '')
                     {
                         removeids = removeids.removeEnd(','); 
                         SendgridDeleteContacts(objsg , 'https://api.sendgrid.com/v3/marketing/lists/'+locationlistId+'/contacts?contact_ids='+removeids);
                     }
                 }
                 removeids = '';
                 if(accountemails != null && accountemails.size() > 0)
                 {
                     for(string email : accountemails)
                     { 
                         //if email is exist in sendgrd list then remove...
                         if(mapemailcons.containsKey(email))
                         {
                             SendgridContact sgc = mapemailcons.get(email);
                             List<string> list_ids = new List<string>();
                             list_ids = sgc.list_ids;
                             system.debug('list_ids**'+list_ids);
                             if(list_ids != null && list_ids.size() > 0 && list_ids.contains(accountlistId))
                             { 
                                 //remove Contact from list 
                                 if(!removeids.Contains(sgc.id + ','))
                                     removeids = removeids + sgc.id + ',';                                      
                             } 
                         }
                     }
                     if(removeids != '')
                     {
                         removeids = removeids.removeEnd(','); 
                         SendgridDeleteContacts(objsg , 'https://api.sendgrid.com/v3/marketing/lists/'+accountlistId+'/contacts?contact_ids='+removeids);
                     }
                 }
                 string delids = '';
                 if(deletecontactemails != null && deletecontactemails.size() > 0)
                 {                         
                     for(string email : deletecontactemails )
                     { 
                         //if email is exist in sendgrd list then remove...
                         if(mapemailcons.containsKey(email))
                         {
                             SendgridContact sgc = mapemailcons.get(email);
                             List<string> list_ids = new List<string>();
                             list_ids = sgc.list_ids; 
                             if(list_ids != null && list_ids.size() > 0 && list_ids.contains(accountlistId))
                             { 
                                 //remove Contact from list 
                                 if(!delids.Contains(sgc.id + ','))
                                     delids = delids + sgc.id + ',';                                      
                             } 
                         }
                     }
                     if(delids != '')
                     {
                         delids = delids.removeEnd(','); 
                         SendgridDeleteContacts(objsg , 'https://api.sendgrid.com/v3/marketing/contacts?ids='+delids);
                     }
                 }
             }
         } 
    }
    public static void SendgridUpsertContacts(Sendgrid_Setting__c objsg ,string data)
    {
        if(objsg != null)
        {
            system.debug('data**'+data);
            system.debug('data v1**'+data.replace('"','\"'));
            string apiKey = objsg.Integration_API_Key__c;   
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.sendgrid.com/v3/marketing/contacts');
            request.setMethod('PUT'); 
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json'); 
            request.setHeader('authorization', 'Bearer '+ apiKey); 
            request.setBody(data);
            HttpResponse response = http.send(request);   
        }
    }
    public static void SendgridDeleteContacts(Sendgrid_Setting__c objsg , string url)
    {
        if(objsg != null)
        {
            string apiKey = objsg.Integration_API_Key__c;   
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(url);
            request.setMethod('DELETE'); 
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
            request.setHeader('authorization', 'Bearer '+ apiKey); 
            HttpResponse response = http.send(request);   
        }
    }
    public static List<SendgridContact> SendgridGetContacts()
    {
        List<SendgridContact> lstSGcontacts = new List<SendgridContact>();        
        Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
        string apiKey = objsg.Integration_API_Key__c;        
        string endpoint = objsg.Email_Activity_EndPoint__c;
        if(objsg != null)
        {
            //Sendgrid Get All Contacts API request
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setEndpoint('https://api.sendgrid.com/v3/marketing/contacts');
            request.setMethod('GET'); 
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
            request.setHeader('authorization', 'Bearer '+ apiKey); 
            HttpResponse response = http.send(request); 
            if (response.getStatusCode() == 200) 
            {               
                Map<String,Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String jsonSubset = JSON.serialize(jsonMap.get('result'));    
                lstSGcontacts = (List<SendgridContact>)JSON.deserialize(jsonSubset, List<SendgridContact>.class);  
            }
        }
        return lstSGcontacts ;
    }
    
    public class Metadata    
    {
        public string self { get; set; }
    }

    public class CustomFields    
    {
        public string Account { get; set; } 
        public string ContactId { get; set; } 
        public string PortalToken { get; set; } 
    }

    public class SendgridContact
    {
        public string address_line_1 { get; set; } 
        public string address_line_2 { get; set; } 
        public object alternate_emails { get; set; } 
        public string city { get; set; } 
        public string country { get; set; } 
        public string email { get; set; } 
        public string first_name { get; set; } 
        public string id { get; set; } 
        public string last_name { get; set; } 
        public List<string> list_ids { get; set; } 
        public string postal_code { get; set; } 
        public string state_province_region { get; set; } 
        public string phone_number { get; set; } 
        public string whatsapp { get; set; } 
        public string line { get; set; } 
        public string facebook { get; set; } 
        public string unique_name { get; set; } 
        public Metadata cmetadata { get; set; } 
        public CustomFields custom_fields { get; set; } 
        public DateTime created_at { get; set; } 
        public string updated_at { get; set; } 
    }
    
    public class CustomFieldIds    
    {
        public string e1_T { get; set; } //cptoken - PortalToken
        public string e2_T { get; set; } //accountname - Account
        public string e3_T { get; set; } //contactid - ContactId 
    }

    public class SG_Contact    
    {
        public string email { get; set; } 
        public string first_name { get; set; } 
        public string last_name { get; set; } 
        public CustomFieldIds custom_fields { get; set; } 
    }
    public class SG_UpsertContact
    {
        public List<string> list_ids;
        public List<SG_Contact> contacts;
    }
}