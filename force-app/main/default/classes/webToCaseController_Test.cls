@isTest
public class webToCaseController_Test {
       static testMethod void webToCase() { 
        webToCaseController.getSelectedType();
        webToCaseController.createCaseWithAttachment('test','test','jpg','Test 1','test@gmail.com','test','test','Risk');
        webToCaseController.createCase('Test 1','test@gmail.com','test','test','Risk');
    }
}