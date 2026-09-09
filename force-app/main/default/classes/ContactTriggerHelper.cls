//Test Class - SendgridHelper_Test
public with sharing class ContactTriggerHelper {
    
    /*public static void checkDuplicates(List<Contact> contacts) {
        system.debug(UserInfo.getName());
        if (UserInfo.getName() != 'Customer Portal') {
            Set<String> contactEmails = new Set<String>();
            for (Contact c : contacts) {
                contactEmails.add(c.Email);
            }
            List<Contact> existingContacts = [select Email from Contact where Email in :contactEmails];
            Set<String> emails = new Set<String>();
            for (Contact c : existingContacts) emails.add(c.Email);
            for (Contact c : contacts) {
                if (emails.contains(c.Email)) c.addError('A contact with the entered e-mail already exists.');
            }
        }
    }*/
     

    //Commented by Bruno following Fátima's request on Jira 1143
    public static void populatePreviousEmail(List<Contact> newContacts, Map<Id, Contact> oldContacts) {
        /*for(Contact c : newContacts){
            if(c.Email != oldContacts.get(c.Id).Email ){ 
                system.debug('Email foi mudado... mapear no previous email->');
                c.previous_email__c = oldContacts.get(c.Id).Email;
            }
        } */

    }
    public static void syncContactsToSendGrid(List<Contact> newContacts, List<Contact> oldContacts, Map<Id, Contact> oldmapContacts) 
    {
        Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
        if(objsg != null && objsg.SyncToSendgrid__c)
        {
            Set<Id> AccountIds = new Set<Id>();
            Set<Id> LocationContactIds = new Set<Id>();
            Set<Id> AccountContactIds = new Set<Id>();
            Set<string> RemoveLocationContactIds = new Set<string>();
            Set<string> RemoveAccountContactIds = new Set<string>();
            Set<string> DeleteContactIds = new Set<string>();
            List<Contact> locationcontacts = new List<Contact>();
            List<Contact> accountcontacts = new List<Contact>();
            Map<Id, Account> mapAccounts = new Map<Id, Account>();
            if(Trigger.IsInsert || Trigger.IsUpdate)
            {
                for(Contact con : newContacts){
                    if(con.AccountId != null)
                    {
                        AccountIds.add(con.AccountId);
                    }
                }
                mapAccounts = new Map<Id, Account>([Select Id, RecordTypeId, RecordType.Name, Enqix_Dead_Live__c from Account where Id =: AccountIds ]);
            }
            if(Trigger.IsAfter && Trigger.IsInsert)
            {            
                for(Contact con : newContacts)
                {
                    if(!con.Unsubscribed__c && con.AccountId != null && mapAccounts != null && mapAccounts.get(con.AccountId) != null)
                    {                
                        Account acc = mapAccounts.get(con.AccountId);
                        if(acc.RecordTypeId != null && acc.Enqix_Dead_Live__c == 'Live')
                        {
                            if(acc.RecordType.Name == 'Location')
                            {
                                LocationContactIds.add(con.Id);
                                locationcontacts.add(con);
                            }                        
                            else if(acc.RecordType.Name == 'Account')
                            {
                                AccountContactIds.add(con.Id);
                                accountcontacts.add(con);
                            }
                        }
                    }                 
                }
            }
            else if(Trigger.IsAfter && Trigger.IsUpdate)
            {
                for(Contact con : newContacts)
                {
                    if(con.AccountId != null && mapAccounts != null && mapAccounts.get(con.AccountId) != null)
                    {                
                        Account acc = mapAccounts.get(con.AccountId);                
                        if(con.Unsubscribed__c != oldmapContacts.get(con.Id).Unsubscribed__c)
                        { 
                            if(con.Unsubscribed__c == true)
                            { 
                                DeleteContactIds.add(con.Email);
                            }
                            else 
                            {
                                if(acc.RecordType.Name == 'Location')
                                { 
                                    LocationContactIds.add(con.Id);
                                    locationcontacts.add(con); 
                                }
                                else if(acc.RecordType.Name == 'Account')
                                { 
                                    AccountContactIds.add(con.Id);
                                    accountcontacts.add(con); 
                                }
                            }
                        }
                        else 
                        {
                            if(acc.RecordType.Name == 'Location')
                            {
                                if(con.FirstName != oldmapContacts.get(con.Id).FirstName || con.LastName != oldmapContacts.get(con.Id).LastName
                                || con.FMCP_Token__c != oldmapContacts.get(con.Id).FMCP_Token__c || con.Email!= oldmapContacts.get(con.Id).Email)
                                {
                                   LocationContactIds.add(con.Id);
                                   locationcontacts.add(con);
                                }  
                                if(con.Email!= oldmapContacts.get(con.Id).Email) 
                                {
                                    //Need to manage remove old email contact from sendgrid
                                    RemoveLocationContactIds.add(oldmapContacts.get(con.Id).Email);
                                }     
                            }
                            else if(acc.RecordType.Name == 'Account')
                            {
                                if(con.FirstName != oldmapContacts.get(con.Id).FirstName || con.LastName != oldmapContacts.get(con.Id).LastName
                                || con.FMCP_Token__c != oldmapContacts.get(con.Id).FMCP_Token__c || con.Email!= oldmapContacts.get(con.Id).Email)
                                {
                                   AccountContactIds.add(con.Id);
                                   accountcontacts.add(con);
                                } 
                                if(con.Email!= oldmapContacts.get(con.Id).Email) 
                                {
                                    //Need to manage remove old email id contact from sendgrid
                                    RemoveAccountContactIds.add(oldmapContacts.get(con.Id).Email);
                                }  
                            }
                        }
                    }
                }
            }
            else if(Trigger.IsBefore && Trigger.IsDelete)
            {
                for(Contact con : oldContacts)
                {
                    if(!con.Unsubscribed__c && con.AccountId != null && mapAccounts != null && mapAccounts.get(con.AccountId) != null)
                    {                
                        Account acc = mapAccounts.get(con.AccountId);
                        if(acc.RecordTypeId != null && acc.Enqix_Dead_Live__c == 'Live')
                        {
                            if(acc.RecordType.Name == 'Location')
                            {
                                RemoveLocationContactIds.add(con.Email);
                            }                        
                            else if(acc.RecordType.Name == 'Account')
                            {
                                RemoveAccountContactIds.add(con.Email);
                            }
                        }
                    } 
                }
            } 
            if(locationcontacts != null || accountcontacts != null )
            {
                SendgridHelper.UpsertContactList(LocationContactIds , AccountContactIds , AccountIds);
            }
            if(RemoveLocationContactIds != null || RemoveAccountContactIds  != null)
            {
                SendgridHelper.RemoveContactfromList(RemoveLocationContactIds, RemoveAccountContactIds, DeleteContactIds);
            }
        }
    }
}