//TestClass - SendgridContactEmail_Test
public class SendGridSendEmail
{
    @TestVisible
    public class ContactemailParameter
    {
        @InvocableVariable(required=true)
        public string templateId;
        @InvocableVariable(required=true)
        public String contactName;
        @InvocableVariable(required=true)
        public String contactEmail;
        @InvocableVariable(required=false)
        public String cpToken;
        @InvocableVariable(required=false)
        public String accountName;
        @InvocableVariable(required=false)
        public String parentAccountName;
        @InvocableVariable(required=false)
        public String outstandingBalance;
        @InvocableVariable(required=false)
        public String orderNumber;
    }  
    
    @InvocableMethod(label='handletoSendcontactemail')
    public static void EmailtoContact(ContactemailParameter[] contactemailParameter)
    { 
        if (!SendGridSetting__c.getOrgDefaults().IsEmailEnabled__c || !SendGridSetting__c.getOrgDefaults().IsFlowEmailEnabled__c) {
            return;
        }
        if(contactemailParameter != null && contactemailParameter[0].templateId != null)
        {
            Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
            SG_ContactEmail ContactEmail = new SG_ContactEmail();
            List<Personalization> personalizations = new List<Personalization>();
            Set<string> conEmails = new Set<string>();
            List<Contact> lstContact = new List<Contact>();
            Map<string, Contact> mapEmailToContact = new Map<string, Contact>();
            
            for(ContactemailParameter cp: contactemailParameter)
            {
               if(cp.contactEmail != null && cp.contactEmail != '')
               {
                   conEmails.add(cp.contactEmail);
               } 
            }
            if(conEmails != null)
            {
                lstContact = [Select Id, Email, Preferences__c from Contact where Email = : conEmails ];
                for(Contact con: lstContact)
                {
                    mapEmailToContact.put(con.Email, con);
                }
                for(ContactemailParameter cp: contactemailParameter)
                {
                    if(mapEmailToContact != null && mapEmailToContact.ContainsKey(cp.contactEmail))
                    {   
                        Personalization perContact = new Personalization();                 
                        Contact cpContact = new Contact();
                        cpContact = mapEmailToContact.get(cp.contactEmail);
                        if(cpContact != null && (cpContact.Preferences__c != 'No Emails' && cpContact.Preferences__c != 'Finance Only'))
                        {
                            To conTo = new To();
                            string cpToken = '';
                            string accountName = '';
                            string parentAccountName = '';
                            string outstandingBalance = '';
                            string orderNumber = '';
                            conTo.email = cp.contactEmail;
                            conTo.name = cp.contactName;
                            perContact.to = new List<To> { conTo };
                            DynamicTemplateData dynamicData = new DynamicTemplateData();
                            dynamicData.contactName = cp.contactName;
                            dynamicData.contactEmail = cp.contactEmail;
                            if(cp.cpToken != null)
                                cpToken = cp.cpToken;
                            if(cp.accountName != null)
                                accountName = cp.accountName;
                            if(cp.parentAccountName != null)
                                parentAccountName = cp.parentAccountName;
                            if(cp.outstandingBalance != null)
                                outstandingBalance = cp.outstandingBalance;      
                            if(cp.orderNumber != null)
                                orderNumber = cp.orderNumber; 
                                
                            dynamicData.cpToken = cpToken ;
                            dynamicData.accountName = accountName ;
                            dynamicData.parentAccountName = parentAccountName;
                            dynamicData.outstandingBalance = outstandingBalance ;
                            dynamicData.orderNumber = orderNumber ;
                            perContact.dynamic_template_data = dynamicData ;
                            perContact.subject = 'Hello !';
                            personalizations.add(perContact);
                        }
                    }
                }
                if(personalizations != null && personalizations.size() > 0)
                { 
                    ContactEmail.personalizations = personalizations ;
                    Fromcls frm = new Fromcls();
                    frm.email = objsg.Sendgrid_From_Email__c;
                    frm.name = objsg.Sendgrid_From_Name__c;
                    ContactEmail.Fromcls = frm ;
                    ReplyTo reply_to = new ReplyTo();    
                    reply_to.email = objsg.Sendgrid_ReplyTo_Email__c;
                    reply_to.name = objsg.Sendgrid_ReplyTo_Name__c;
                    ContactEmail.reply_to = reply_to ;
                    ContactEmail.template_id = contactemailParameter[0].templateId;
                    string data = JSON.serialize(ContactEmail);  
                    data = data.replace('fromcls','from'); 
                    SendEmail(objsg.Integration_API_Key__c, data);     
                } 
            }  
        }
    } 
    
    @future (callout=true)
    private static void SendEmail(string apiKey, string data)
    {     
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('https://api.sendgrid.com/v3/mail/send');
        request.setMethod('POST'); 
        request.setTimeout(120000);
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setHeader('authorization', 'Bearer '+ apiKey); 
        request.setBody(data);
        HttpResponse response = http.send(request);  
    }
    public class To    {
        public string email { get; set; } 
        public string name { get; set; } 
    }

    public class DynamicTemplateData    {
        public string contactName { get; set; } 
        public string cpToken { get; set; } 
        public string contactEmail { get; set; }  
        public string accountName { get; set; }
        public string parentAccountName { get; set; }
        public string outstandingBalance { get; set; }
        public string orderNumber { get; set; }
    }

    public class Personalization    {
        public List<To> to { get; set; } 
        public DynamicTemplateData dynamic_template_data { get; set; } 
        public string subject { get; set; } 
    }

    public class Fromcls {
        public string email { get; set; } 
        public string name { get; set; } 
    }

    public class ReplyTo    {
        public string email { get; set; } 
        public string name { get; set; } 
    }

    public class SG_ContactEmail
    {
        public List<Personalization> personalizations { get; set; } 
        public Fromcls fromcls { get; set; } 
        public ReplyTo reply_to { get; set; } 
        public string template_id { get; set; } 
    }     
}