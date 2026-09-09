//Test Class - EmailActivityScheduler_Test
public with sharing class EmailActivityTriggerHelper
{
    //Attach Email Activity to the right contact in Salesforce from sendgrid – matching on email address
     public static void populateContactfromEmail(List<Email_Activity__c> newEmailActivities)
     {
         Set<string> contactEmails = new Set<string>();
         for(Email_Activity__c activity : newEmailActivities)
         {
            if(activity.From_Email__c != null)
            {
                contactEmails.add(activity.From_Email__c);
            }
            if(activity.To_Email__c != null)
            {
                contactEmails.add(activity.To_Email__c);
            }
         }
         if(contactEmails != null && contactEmails.size() > 0)
         {
             Map<Id, Contact> mapcontacts = new Map<Id, Contact>([Select Id, Email from Contact where Email =: contactEmails]);
             Map<string, Contact> mapemailcontacts = new Map<string, Contact>();
             if(mapcontacts != null && mapcontacts.size() > 0)
             {
                 for(Contact con : mapcontacts.values())
                 {
                     mapemailcontacts.put(con.Email, con);
                 }
             }
             for(Email_Activity__c activity : newEmailActivities)
             {
                if(activity.From_Email__c != null && mapemailcontacts != null && mapemailcontacts.get(activity.From_Email__c) != null)
                {
                    activity.Email_From__c =  mapemailcontacts.get(activity.From_Email__c).Id;
                }
                if(activity.To_Email__c != null && mapemailcontacts != null && mapemailcontacts.get(activity.To_Email__c) != null)
                {
                    activity.Email_Sent_To__c =  mapemailcontacts.get(activity.To_Email__c).Id;
                }
             }
         }
     }
}