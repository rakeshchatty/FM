@istest
private class ContactListControllerTest
{
    @istest private static void testMethod1()
    {
        //SELECT id, name, BillingStreet, phone FROM Account LIMIT 50];
        
        Account parentAccount = TestDataHelper.createAccount();
        INSERT parentAccount;
        
        Contact contact = TestDataHelper.insertContact(parentAccount.Id, 'FirstMile');

        Contact c1 = new Contact();
        c1.FirstName = 'Test';
        c1.LastName = 'testes';
        c1.AccountId = parentAccount.Id;
        c1.Email = 'nuno123@hotmail.com';
		insert c1;
        
        String searchKey = '';
        String ObjectName = 'Contact';
        String recordId = '123456789';
        String selectedRecordId = Id.valueOf(c1.Id);
        
        ContactLookupFlowController.fetchLookUpValues(searchKey,ObjectName,recordId,selectedRecordId);
        ContactLookupFlowController.updateCases(selectedRecordId,recordId);
    }
}