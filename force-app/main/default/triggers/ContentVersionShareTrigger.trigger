trigger ContentVersionShareTrigger on ContentVersion (after insert) {

        List<user> users = [select user.id, user.Email, user.FirstName, user.LastName, user.profile.name, user.Username, user.IsActive 
        FROM user, user.profile 
        where Username = 'integration@thefirstmile.co.uk' and user.IsActive=true];
        Set<Id> contentDocumentIdSet = new Set<Id>();

        for(ContentVersion cv:trigger.new)
        {
            if(cv.ContentDocumentId != null)
            {
                contentDocumentIdSet.add(cv.ContentDocumentId);
            }
        }

        List <ContentDocumentLink> lstContentDocumentlink = [SELECT ContentDocumentId, LINKEDENTITYID 
                                                            FROM ContentDocumentLink WHERE ContentDocumentId IN:contentDocumentIdSet LIMIT 1];
    
    	system.debug('lstContentDocumentlink-->' + lstContentDocumentlink.size());


    	List<ContentDocumentLink> oldContentDocumentList = [Select Id from ContentDocumentLink Where ContentDocumentId IN:contentDocumentIdSet AND LinkedEntityID IN:users];
    
        List<ContentDocumentLink> ContentDocumentList = new List<ContentDocumentLink>();


    if(oldContentDocumentList.size() == 0){
        for(ContentVersion cv:trigger.new)
        {
            if(cv.ContentDocumentId != null && !lstContentDocumentlink.isEmpty())
            {
                for(user u:users){
                    if(u.Id != cv.OwnerId){
                        ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId=cv.ContentDocumentId,LINKEDENTITYID = u.Id,SHARETYPE='V');
                        ContentDocumentList.add(cdl);  
                    }
                }
            }
        }
    }

        insert ContentDocumentList;
}