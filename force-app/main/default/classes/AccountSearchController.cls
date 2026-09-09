public class AccountSearchController {

    public string PostCode {get; set;}
    public List<SelectOption> EnqixDeadLive {get; set;}
    public string selectedEnqixDeadLive {get; set;}
    public String selectedRecordTypeid {get;set;}
    public string AccountName {get;set;}
    public List<SelectOption> recordtypeLst {get;set;}
    public list<Account> accs {get; set;}
    public string AccStreet {get; set;}
    
    public AccountSearchController()
    {
        recordtypeLst = new List<SelectOption>();
        EnqixDeadLive = new List<SelectOption>();
        
        accs = new list<Account>();
        
        list<RecordType> rtlist = [Select id,Name from recordtype where sobjecttype = 'Account'];
        
        recordtypeLst.add(new SelectOption('All','All'));
        
        for(RecordType rt : rtlist)
        {
            recordtypeLst.add(new SelectOption(rt.id,rt.Name));
            if(rt.Name == 'Location'){
                selectedRecordTypeid = rt.Id;
            }
        }
        
        
        EnqixDeadLive.add(new SelectOption('none','-None-'));
        EnqixDeadLive.add(new SelectOption('Dead','Dead'));
        EnqixDeadLive.add(new SelectOption('Live','Live'));
        selectedEnqixDeadLive = 'Live';
        
        accs = [Select id,Name,BillingPostalCode,Owner.Name,IMAGE__c,Real_Classification__c,BillingStreet,BillingState,BillingCountry,BillingCity,Enqix_Dead_Live__c from Account order by LastModifiedDate desc limit 20];
    }
    
    public PageReference SearchAccount()
    {
        if((PostCode == null || PostCode == '') && (AccountName == null || AccountName == ''))
        {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,'Please enter either Post Code or Name to search'));
            return null;
        }
        
        String SOQL = 'Select id,Name,BillingPostalCode,Owner.Name,IMAGE__c,Real_Classification__c,BillingStreet,BillingState,BillingCountry,BillingCity,Enqix_Dead_Live__c from Account  where BillingPostalCode like \'%'+PostCode+'%\' '; 
        
        if(selectedRecordTypeid != 'All')
            SOQL += ' and Recordtypeid =:selectedRecordTypeid';
            
        if(selectedEnqixDeadLive != 'none')
            SOQL += ' and Enqix_Dead_Live__c =:selectedEnqixDeadLive';
        
        if(AccountName != null && AccountName != '')
            SOQL += ' and Name like \'%'+AccountName+'%\'';
        
        if(AccStreet != null && AccStreet != '')
            SOQL += ' and BillingStreet like \'%'+AccStreet+'%\'';
            
            
        SOQL += ' limit 1000';
        
        accs = Database.Query(SOQL);
        
        return null;
    }
}