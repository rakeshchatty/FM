//Test Class - SendgridHelper_Test
public class AccountOperationTriggerHelper 
{
    public static void syncSendgridContacts(List<Account> newAccounts, List<Account> oldAccounts, Map<Id, Account> mapAccounts, Map<Id, Account> oldmapAccounts) 
    {
        Sendgrid_Setting__c objsg = Sendgrid_Setting__c.getValues('IntegrationId');
        if(objsg != null && objsg.SyncToSendgrid__c)
        {
            Set<Id> AccountIds = new Set<Id>();
            Set<Id> LocationAccountIds = new Set<Id>();
            Set<Id> AccountAccountIds = new Set<Id>();
            Set<Id> RemoveLocationAccountIds = new Set<Id>();
            Set<Id> RemoveAccountAccountIds = new Set<Id>();
            
            Set<Id> LocationContactIds = new Set<Id>();
            Set<Id> AccountContactIds = new Set<Id>();
            Set<string> RemoveLocationContactIds = new Set<string>();
            Set<string> RemoveAccountContactIds = new Set<string>();
            Set<Id> DeleteAccountIds = new Set<Id>();
            Set<string> DeleteContactIds = new Set<string>();
            List<Contact> locationcontacts = new List<Contact>();
            List<Contact> accountcontacts = new List<Contact>();
            //Query for the Account record types
            List<RecordType> rtypes = [Select Name, Id From RecordType where sObjectType='Account' and isActive=true];         
            //Create a map between the Record Type Name and Id for easy retrieval
            Map<String,String> accountRecordTypes = new Map<String,String>{};
            for(RecordType rt: rtypes)
               accountRecordTypes.put(rt.Name,rt.Id);
            for(Account acc : newAccounts)
            {
                if(acc.Enqix_Dead_Live__c != oldmapAccounts.get(acc.Id).Enqix_Dead_Live__c || acc.RecordTypeId != oldmapAccounts.get(acc.Id).RecordTypeId)
                {
                    system.debug('Enqix_Dead_Live__c **'+acc.Enqix_Dead_Live__c );
                    system.debug('RecordTypeId **'+acc.RecordTypeId);
                     
                    if(acc.Enqix_Dead_Live__c == 'Live' && acc.RecordTypeId != null && acc.RecordTypeId == accountRecordTypes.get('Location'))
                    {
                        LocationAccountIds.add(acc.Id);
                        RemoveAccountAccountIds.add(acc.Id);
                    }
                    else if(acc.Enqix_Dead_Live__c == 'Live' && acc.RecordTypeId != null && acc.RecordTypeId == accountRecordTypes.get('Account'))
                    {
                        AccountAccountIds.add(acc.Id);
                        RemoveLocationAccountIds.add(acc.Id);
                    }                
                    else
                    {
                        //RemoveAccountAccountIds.add(acc.Id);
                        //RemoveLocationAccountIds.add(acc.Id);
                        DeleteAccountIds.add(acc.Id);
                    }
                    AccountIds.add(acc.Id);
                }
                else if(acc.Name != oldmapAccounts.get(acc.Id).Name && acc.Enqix_Dead_Live__c == 'Live')
                {
                    if(acc.RecordTypeId != null && acc.RecordTypeId == accountRecordTypes.get('Location'))
                    {
                        LocationAccountIds.add(acc.Id); 
                    }
                    else if(acc.RecordTypeId != null && acc.RecordTypeId == accountRecordTypes.get('Account'))
                    {
                        AccountAccountIds.add(acc.Id);
                    }
                    AccountIds.add(acc.Id);
                }
            }
            if(AccountIds != null)
            {
                List<Contact> lstcontacts = [Select Id, Name, FirstName, LastName, Email, FMCP_Token__c , AccountId, Unsubscribed__c from Contact where AccountId =: AccountIds and Unsubscribed__c = false];
                if(lstcontacts != null && lstcontacts.size() > 0)
                {
                    Map<Id, List<Contact>> mapacccontacts = new Map<Id, List<Contact>>();
                    for(Contact con : lstcontacts)
                    {
                        if(mapacccontacts != null && mapacccontacts.containsKey(con.AccountId))
                        {
                            mapacccontacts.get(con.AccountId).add(con);
                        }
                        else
                        {
                            mapacccontacts.put(con.AccountId , new List<Contact> { con });
                        }
                    }
                    if(LocationAccountIds != null)
                    {
                        for(Id accId : LocationAccountIds)
                        {
                            if(mapacccontacts != null && mapacccontacts.containsKey(accId))
                            {
                                List<Contact> contacts = new List<Contact>();
                                contacts = mapacccontacts.get(accId);
                                if(contacts != null && contacts.size() > 0)
                                {
                                    for(Contact c : contacts)
                                    {
                                        LocationContactIds.add(c.Id);
                                        locationcontacts.add(c);
                                    }
                                }
                            }   
                        }
                    }
                    if(AccountAccountIds != null)
                    {
                        for(Id accId : AccountAccountIds)
                        {
                            if(mapacccontacts != null && mapacccontacts.containsKey(accId))
                            {
                                List<Contact> contacts = new List<Contact>();
                                contacts = mapacccontacts.get(accId);
                                if(contacts != null && contacts.size() > 0)
                                {
                                    for(Contact c : contacts)
                                    {
                                        AccountContactIds.add(c.Id);
                                        accountcontacts.add(c);
                                    }
                                }
                            }   
                        }
                    }
                    if(DeleteAccountIds != null)
                    {
                        for(Id accId : DeleteAccountIds )
                        {
                            if(mapacccontacts != null && mapacccontacts.containsKey(accId))
                            {
                                List<Contact> contacts = new List<Contact>();
                                contacts = mapacccontacts.get(accId);
                                if(contacts != null && contacts.size() > 0)
                                {
                                    for(Contact c : contacts)
                                    {
                                        DeleteContactIds.add(c.Email); 
                                    }
                                }
                            }   
                        }
                    }
                    if(RemoveLocationAccountIds != null)
                    {
                        for(Id accId : RemoveLocationAccountIds)
                        {
                            if(mapacccontacts != null && mapacccontacts.containsKey(accId))
                            {
                                List<Contact> contacts = new List<Contact>();
                                contacts = mapacccontacts.get(accId);
                                if(contacts != null && contacts.size() > 0)
                                {
                                    for(Contact c : contacts)
                                    {
                                        RemoveLocationContactIds.add(c.Email);
                                    }
                                }
                            }
                        }
                    }
                    if(RemoveAccountAccountIds != null)
                    {
                        for(Id accId : RemoveAccountAccountIds)
                        {
                            if(mapacccontacts != null && mapacccontacts.containsKey(accId))
                            {
                                List<Contact> contacts = new List<Contact>();
                                contacts = mapacccontacts.get(accId);
                                if(contacts != null && contacts.size() > 0)
                                {
                                    for(Contact c : contacts)
                                    {
                                        RemoveAccountContactIds.add(c.Email);
                                    }
                                }
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