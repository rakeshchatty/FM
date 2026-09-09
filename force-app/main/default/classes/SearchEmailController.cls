public class SearchEmailController {
    @AuraEnabled
    public static List<EmailMessageResult> fetchAccount(String searchKeyWord, String fieldName, String fieldFilterValue) {
        List < EmailMessage > returnList = new List < EmailMessage > ();
        List<EmailMessageResult> emailMessageSearchResults = new List<EmailMessageResult>();
        String filterStr = fieldFilterValue == 'Equals' ? ( fieldName + ' = :searchKeyWord ') : ( fieldName + ' Like \'%' + searchKeyWord + '%\'' );
        String query = 'Select Id, HtmlBody, Subject, FromName, FromAddress, ToAddress, Status, MessageDate From EmailMessage Where ' + filterStr + ' Limit 100';
        for (EmailMessage emsg: Database.query(query)) {
            EmailMessageResult emr = new EmailMessageResult();
            emr.emailMessageRecord = emsg;
            emr.helpText = '' + emsg.FromName + '<br>' + emsg.FromAddress ;
            returnList.add(emsg);
            emailMessageSearchResults.add(emr);
        }
        return emailMessageSearchResults;
    }
    
    @AuraEnabled
    public static Map<String, String> fetchFieldOptions(){
        Map<String, String> fieldOptions = new Map<String, String>();
        fieldOptions.put( '-- NONE --' , 'NONE' );
        fieldOptions.put( 'Subject' , 'Subject' );
        fieldOptions.put( 'From Name' , 'FromName' );
        fieldOptions.put( 'From Email' , 'FromAddress' );
        fieldOptions.put( 'Email Body' , 'TextBody' );
        return fieldOptions;
    }
    
    @AuraEnabled
    public static Map<String, String> fetchFieldFilterOptions(){
        Map<String, String> fieldOptions = new Map<String, String>();
        fieldOptions.put( 'Equals' , 'Equals' );
        fieldOptions.put( 'Contains' , 'Contains' );
        return fieldOptions;
    }
    
    public Class EmailMessageResult{
        @AuraEnabled
        public EmailMessage emailMessageRecord {get; set;}
        @AuraEnabled
        public String helpText { get; set;}
    }
}