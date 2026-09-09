@isTest
public class CloseCaseController_Test {
    
    private static testmethod void UnitTest() {
        
        Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

        Case cas = new Case(Status ='New', Priority = 'Medium', Origin = 'Email', Type = 'Missed Collection', Location__c = location.Id);
        INSERT cas;
        
        CloseCaseController.RetreiveCase(cas.Id);
        CloseCaseController.saveCase(cas);
    }
}