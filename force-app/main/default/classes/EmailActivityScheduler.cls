global class EmailActivityScheduler implements Schedulable
{
    global void execute(SchedulableContext SC) 
    {
        processEmailActivity();
        datetime nextScheduleTime = system.now();
        string jobName = 'Email Activities' + nextScheduleTime.format('ss mm HH dd MM ? yyyy');
        string strSeconds = '00';
        string strMinutes = '05';     
        string strHours = '00';
        string strDay_of_month = '*';
        string strMonth = '*';
        string strDay_of_week = '?';
        String sch = strSeconds + ' ' + strMinutes + ' ' + strHours + ' ' + strDay_of_month + ' ' + strMonth + ' ' + strDay_of_week;
  
        EmailActivityScheduler p = new EmailActivityScheduler(); 
        system.schedule(jobName, sch , p);
        
        //this section of code will abort the current schedule job
        system.abortJob(sc.getTriggerId());          
    }
    
    @future(callout=true)
    public static void processEmailActivity()
    {
        string PrevDate = string.valueof(Date.today().addDays(-1));
        string fromDate = PrevDate + 'T00:00:00.000Z';
        string toDate = PrevDate +'T23:59:59.999Z';
        system.debug('from encrypt**'+EncodingUtil.urlEncode(fromDate , 'UTF-8'));
        system.debug('to encrypt**'+EncodingUtil.urlEncode(toDate , 'UTF-8'));
        
        string PrevDatetime = string.valueof(datetime.now().addDays(-1));
        Long Prevtimestamp = DateTime.valueOf(PrevDatetime.split(' ')[0] + ' 01:00:00').getTime(); 
        string CurrDate = string.valueof(datetime.now());
        Long Currtimestamp = DateTime.valueOf(CurrDate.split(' ')[0] + ' 01:00:00').getTime(); 
        List<bounceactivity> bounceemailActivitites = new List<bounceactivity>();
        Map<string,bounceactivity> mapbounceactivity = new Map<string,bounceactivity>();
         
        List<blockactivity> blockemailActivitites = new List<blockactivity>();
        Map<string,blockactivity> mapblockactivity = new Map<string,blockactivity>();
        Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
        if(objsg != null)
        {
            string apiKey = objsg.Integration_API_Key__c;
            string query = '&query=last_event_time%20BETWEEN%20TIMESTAMP%20%22{start_date}%22%20AND%20TIMESTAMP%20%22{end_date}%22';
            query = query.replace('{start_date}',fromDate).replace('{end_date}',toDate);
            string endpoint = objsg.Email_Activity_EndPoint__c;
            
            //Sendgrid Email Activity API request
            Http http = new Http();
            
            //sendgrid bounce api - GET https://api.sendgrid.com/v3/suppression/bounces?start_time={start_time}&end_time={end_time}
            string bounceendpoint = 'https://api.sendgrid.com/v3/suppression/bounces?start_time={start_time}&end_time={end_time}';
            bounceendpoint = bounceendpoint.replace('{start_time}',string.valueof(Prevtimestamp).substring(0,string.valueof(Prevtimestamp).length()-3));
            bounceendpoint = bounceendpoint.replace('{end_time}',string.valueof(Currtimestamp).substring(0,string.valueof(Currtimestamp).length()-3)); 
            system.debug('bounceendpoint **'+bounceendpoint );
            HttpRequest request = new HttpRequest();
            request.setEndpoint(bounceendpoint);
            request.setMethod('GET'); 
            request.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
            request.setHeader('authorization', 'Bearer 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'); 
            HttpResponse response = http.send(request); 
             
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200 && !Test.isRunningTest()) 
            {               
                bounceemailActivitites  = (list<bounceactivity>)JSON.deserialize(response.getBody(), list<bounceactivity>.class);                
                if(bounceemailActivitites != null && bounceemailActivitites.size() > 0)
                {
                    for(bounceactivity email : bounceemailActivitites)
                    {
                        bounceactivity bactivity = new bounceactivity();
                        bactivity.email = email.email;
                        bactivity.reason = email.reason;
                        mapbounceactivity.put(email.email, bactivity);
                    } 
                }
            }
            
            //sendgrid block api - GET https://api.sendgrid.com/v3/suppression/blocks?start_time={start_time}&end_time={end_time}
            string blockendpoint = 'https://api.sendgrid.com/v3/suppression/blocks?start_time={start_time}&end_time={end_time}';
            blockendpoint = blockendpoint.replace('{start_time}',string.valueof(Prevtimestamp).substring(0,string.valueof(Prevtimestamp).length()-3));
            blockendpoint = blockendpoint.replace('{end_time}',string.valueof(Currtimestamp).substring(0,string.valueof(Currtimestamp).length()-3)); 
            request = new HttpRequest();
            request.setEndpoint(blockendpoint);
            request.setMethod('GET'); 
            request.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
            request.setHeader('authorization', 'Bearer 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'); 
            response = http.send(request); 
             
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200 && !Test.isRunningTest()) 
            {  
                blockemailActivitites = (list<blockactivity>)JSON.deserialize(response.getBody(), list<blockactivity>.class);                              
                if(blockemailActivitites != null && blockemailActivitites.size() > 0)
                {
                    for(blockactivity email : blockemailActivitites)
                    {
                        blockactivity bactivity = new blockactivity();
                        bactivity.email = email.email;
                        bactivity.reason = email.reason;
                        mapblockactivity.put(email.email, bactivity);
                    } 
                }
            }
            
            request = new HttpRequest();
            request.setEndpoint(endpoint + query);
            request.setMethod('GET'); 
            request.setTimeout(120000);
            request.setHeader('Content-Type', 'application/json;charset=UTF-8'); 
            request.setHeader('authorization', 'Bearer '+ apiKey); 
            response = http.send(request);   
            // If the request is successful, parse the JSON response.
            if (response.getStatusCode() == 200) 
            {
                System.debug('Execute successful**'+response.getBody());                
                Map<String,Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(response.getBody());
                String jsonSubset = JSON.serialize(jsonMap.get('messages'));    
                List<emailactivity> emailActivitites = (List<emailactivity>)JSON.deserialize(jsonSubset, List<emailactivity>.class); 
                if(emailActivitites != null && emailActivitites.size() > 0)
                {
                    List<Email_Activity__c> lstEmailActivities = new List<Email_Activity__c>();
                    for(emailactivity activity : emailActivitites)
                    {
                        Email_Activity__c act = new Email_Activity__c();
                        act.From_Email__c = activity.from_email;
                        act.To_Email__c = activity.to_email;
                        act.Subject__c = activity.subject;
                        act.Message_Id__c = activity.msg_id;
                        act.Status__c = activity.status;
                        if(act.Status__c != 'delivered')
                        {
                            system.debug('to email**'+activity.to_email);
                            if(mapbounceactivity != null && mapbounceactivity.size() > 0 && mapbounceactivity.containskey(activity.to_email))
                            {
                                act.Event__c = 'Bounced';
                                act.Reason__c = mapbounceactivity.get(activity.to_email).reason;
                            }
                            else if(mapblockactivity != null && mapblockactivity.size() > 0 && mapblockactivity.containskey(activity.to_email))
                            {
                                act.Event__c = 'Blocked';
                                act.Reason__c = mapblockactivity.get(activity.to_email).reason;
                            }
                        }
                        act.Count_of_Opens__c = activity.opens_count;
                        act.Count_of_Clicks__c = activity.clicks_count;
                        act.Event_Time__c = activity.last_event_time;
                        lstEmailActivities.add(act);
                    }
                    if(lstEmailActivities != null && lstEmailActivities.size() > 0)
                    {
                        Database.Insert(lstEmailActivities, false);
                    }
                }
            } 
        }
    }
    
    public class emailactivity {
        public string from_email { get; set; } 
        public string msg_id { get; set; } 
        public string subject { get; set; } 
        public string to_email { get; set; } 
        public string status { get; set; } 
        public integer opens_count { get; set; } 
        public integer clicks_count { get; set; } 
        public DateTime last_event_time { get; set; }         
    } 
    
    public class bounceactivity {
        public string email { get; set; } 
        public string reason { get; set; }       
    } 
    public class blockactivity {
        public string email { get; set; } 
        public string reason { get; set; }       
    } 
}