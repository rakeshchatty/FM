@isTest
public class SearchEmailControllerTest {
    @isTest
    static void fetchEmailTest(){
        EmailMessage msg = new EmailMessage();
        msg.FromName = 'Einsteam';
        msg.FromAddress = 'einsteam@einsteam.com';
        msg.TextBody = 'Testing Email Message';
        Insert msg;
        
        Test.setFixedSearchResults( new List<String>{msg.Id});
        
        Test.startTest();
        	List<SearchEmailController.EmailMessageResult> emailMsgs = SearchEmailController.fetchAccount('Einsteam', 'FromName', 'Equals');
        	system.assert( emailMsgs.size() == 1 );
        	system.assert( SearchEmailController.fetchFieldOptions().size() > 0 );
        	system.assert( SearchEmailController.fetchFieldFilterOptions().size() > 0 );
        Test.stopTest();
    }
}