//TestClass - SendgridContactEmail_Test
public class SendGridSendServiceFinanceContactEmail
{
    public class ServiceFinanceContactemailParameter
    {
        @InvocableVariable(required=true)
        public string templateId;
        @InvocableVariable(required=true)
        public string role;
        @InvocableVariable(required=false)
        public String accountName;
        @InvocableVariable(required=true)
        public String accountId;
        @InvocableVariable(required=false)
        public String parentAccountName;
        @InvocableVariable(required=false)
        public String outstandingBalance;
        @InvocableVariable(required=false)
        public String orderNumber;        
    }
    
    @InvocableMethod(label='sendservicefinancecontactemail')
    public static void EmailtoServicefinanceContact(ServiceFinanceContactemailParameter[] servicefinanceemailParameter)
    {
        if (!SendGridSetting__c.getOrgDefaults().IsEmailEnabled__c || !SendGridSetting__c.getOrgDefaults().IsFlowEmailEnabled__c) {
            return;
        }
        if(servicefinanceemailParameter != null && servicefinanceemailParameter[0].templateId != null)
        {
            Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
            SG_ServiceContactEmail ServiceContactEmail = new SG_ServiceContactEmail();
            List<Personalization> personalizations = new List<Personalization>();
            Set<Id> accountIds = new Set<Id>();
            Set<Id> contactIds = new Set<Id>();
            List<AccountContactRelation> lstAccConRelation = new List<AccountContactRelation>();
            map<Id,List<AccountContactRelation>> accountContactMap = new map<Id,List<AccountContactRelation>>();
            
            Map<Id, Contact> mapContacts = new Map<Id,Contact>();
            for(ServiceFinanceContactemailParameter sfp: servicefinanceemailParameter)
            {
                if(sfp.accountId != null && sfp.accountId != '')
                {
                    accountIds.add(sfp.accountId);
                }
            }
            if(accountIds != null && accountIds.size() > 0)
            { 
                lstAccConRelation = [SELECT Id, AccountId, ContactId, Contact.FMCP_Token__c, Contact.Preferences__c, Contact.Name, Contact.Email, Roles FROM AccountContactRelation where Roles =: servicefinanceemailParameter[0].role and AccountId =: accountIds];
                
                //system.debug('lstAccConRelation **'+lstAccConRelation );
                for(AccountContactRelation record : lstAccConRelation )
                {
                     contactIds.add(record.ContactId);
                     if(accountContactMap.ContainsKey(record.AccountId))
                     {
                         accountContactMap.get(record.AccountId).add(record);
                     }
                     else
                     {
                         accountContactMap.put(record.AccountId, new List<AccountContactRelation> { record });
                     }
                }    
            }
            if(contactIds != null)
            {
                mapContacts = new Map<Id,Contact>([Select Id, FMCP_Token__c, Preferences__c, Name, Email from Contact where Id=: contactIds ]);
            }
            for(ServiceFinanceContactemailParameter sfp: servicefinanceemailParameter)
            { 
                if(sfp.accountId != null && sfp.accountId != '' && accountContactMap != null && accountContactMap.ContainsKey(sfp.accountId))
                {
                    List<AccountContactRelation> lstrelationContacts = new List<AccountContactRelation>();
                    
                    lstrelationContacts = accountContactMap.get(sfp.accountId);
                    //system.debug('lstrelationContacts **'+lstrelationContacts );
                    if(lstrelationContacts != null && lstrelationContacts.size() > 0)
                    {
                        for(AccountContactRelation ac : lstrelationContacts )
                        {
                            //system.debug('ac**'+ac);
                            Contact currCon = new Contact();
                            Personalization perContact = new Personalization();
                            if(mapContacts != null && mapContacts.ContainsKey(ac.ContactId))
                            {
                                currCon = mapContacts.get(ac.ContactId);   
                                //system.debug('contact**'+currCon);
                                string Preferences = currCon.Preferences__c;
                                string Role = servicefinanceemailParameter[0].role;
                                if(Role == 'Service Contact' && (Preferences  != 'No Emails' && Preferences  != 'Finance Only') || 
                                   Role == 'Finance Contact' && (Preferences  != 'No Emails'))
                                { 
                                    List<To> lstTos = new List<To>();
                                    To conTo = new To();              
                                    conTo.Name = currCon.Name;
                                    conTo.Email = currCon.Email;
                                    lstTos.add(conTo); 
                                    //system.debug('lstTos**'+lstTos);
                                    perContact.to = lstTos;
                                    DynamicTemplateData dynamicData = new DynamicTemplateData();
                                    dynamicData.accountName = sfp.accountName;
                                    string parentAccountName = '';
                                    string outstandingBalance = '';
                                    string orderNumber = '';
                                    string contactToken = '';
                                    if(sfp.parentAccountName != null)
                                        parentAccountName = sfp.parentAccountName;
                                    if(sfp.outstandingBalance != null)
                                        outstandingBalance = sfp.outstandingBalance;      
                                    if(sfp.orderNumber != null)
                                        orderNumber  = sfp.orderNumber;  
                                    if(currCon.FMCP_Token__c != null)
                                        contactToken = currCon.FMCP_Token__c;
                                        
                                    dynamicData.parentAccountName = parentAccountName; 
                                    dynamicData.outstandingBalance = outstandingBalance;
                                    dynamicData.orderNumber = orderNumber;
                                    dynamicData.contactToken = contactToken ;
                                    perContact.dynamic_template_data = dynamicData ;
                                    perContact.subject = 'Hello !';
                                    personalizations.add(perContact); 
                                    //system.debug('dynamicData **'+dynamicData );
                                    //system.debug('personalizations**'+personalizations);
                                }
                            }
                        }
                    }
                }
            }
            if(personalizations != null && personalizations.size() > 0)
            { 
                ServiceContactEmail.personalizations = personalizations ;
                Fromcls frm = new Fromcls();
                frm.email = objsg.Sendgrid_From_Email__c;
                frm.name = objsg.Sendgrid_From_Name__c;
                ServiceContactEmail.Fromcls = frm ;
                ReplyTo reply_to = new ReplyTo();    
                reply_to.email = objsg.Sendgrid_ReplyTo_Email__c;
                reply_to.name = objsg.Sendgrid_ReplyTo_Name__c;
                ServiceContactEmail.reply_to = reply_to ;
                ServiceContactEmail.template_id = servicefinanceemailParameter[0].templateId;
                string data = JSON.serialize(ServiceContactEmail);  
                data = data.replace('fromcls','from');                 
                SendEmail(objsg.Integration_API_Key__c, data);  
            }
        }
    }
 
    @future (callout=true)
    private static void sendEmail(string apiKey, string data) {   
        system.debug('data **'+data );  
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
        public string accountName { get; set; }
        public string parentAccountName { get; set; }
        public string outstandingBalance { get; set; }
        public string orderNumber { get; set; }
        public string contactToken { get; set; } 
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

    public class SG_ServiceContactEmail
    {
        public List<Personalization> personalizations { get; set; } 
        public Fromcls fromcls { get; set; } 
        public ReplyTo reply_to { get; set; } 
        public string template_id { get; set; } 
    }   
}