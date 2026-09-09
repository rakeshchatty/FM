public class ContactLookupFlowController {
    @AuraEnabled
    public static List < sObject > fetchLookUpValues(String searchKeyWord, String ObjectName, string RecordId, string selectedRecordToDelete) {
        String searchKey = searchKeyWord + '%';
        List < sObject > returnList = new List < sObject > ();
        system.debug('selectedRecordToDelete --> '+selectedRecordToDelete);
        // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5  
        //String sQuery =  'select id, Name from ' + ObjectName + ' where AccountId = ' + RecordId + ' order by createdDate DESC';
        List < Contact > contactRecord = [Select Id from Contact where Id =: selectedRecordToDelete];
        List < Contact > lstOfRecords = [select Id, Name from Contact where Name LIKE: searchKey AND Id NOT IN: contactRecord order by createdDate DESC];
        
        for (sObject obj: lstOfRecords) {
            returnList.add(obj);
        }
        return returnList;
    }
    
    @AuraEnabled
    public static List < sObject > updateCases(string selectedRecordToDelete, string selectedRecord){
        List < sObject > returnList = new List < sObject > ();
        List <Case> casesToUpdate = [Select Id, ContactId from Case where ContactId =: selectedRecordToDelete];
        system.debug('casesToUpdate --> '+casesToUpdate.size());
        for(Case eachCase: casesToUpdate){
            eachCase.ContactId = selectedRecord;
 
        }
        update casesToUpdate;
        Contact contToDelete = [Select id from Contact where id =: selectedRecordToDelete];
        delete contToDelete;
        return returnList;
    }
}