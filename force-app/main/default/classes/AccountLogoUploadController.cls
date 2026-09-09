public class AccountLogoUploadController{

    public Account acc {get; set;}
    public string accId ;
    
    public blob file { get; set; }
    
    public AccountLogoUploadController(ApexPages.StandardController controller) {
        accId = ApexPages.currentPage().getParameters().get('id');
        system.debug('accId:: '+accId);
        if(accId != null){
            list<Account> AccList = new list<Account>();
            AccList = [Select Id, Name, (Select Id, Name from Attachments where Name = 'Account_Logo') from Account where Id = :AccId];
            if(AccList.size() > 0){
                acc = AccList[0];
            }
        }
    }


    public PageReference upload() {
        try{
            Attachment att = new Attachment();
            
            boolean isAttachFound = false;
            if(acc != null){
                for(attachment attch : acc.Attachments){
                    att.Id = attch.Id;
                    isAttachFound = true;
                }
                
                
            }
            att.Name = 'Account_Logo';
            att.Body = file;
            if(!isAttachFound)
            att.ParentId = accId ;
            upsert att;
            
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Info,'Logo uploaded successfully');
            ApexPages.addMessage(myMsg);
            return null;
        }
        catch(exception ex){
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Error: '+ex.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
        
    }
}