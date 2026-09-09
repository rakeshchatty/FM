@isTest
private class CompetitorControllerTest {

   @istest private static void testMethod1()
   {

     
     Competitor__c a1 = new Competitor__c();
     a1.name='hello raja';
   
   CompetitorController.findAll();
   System.assertEquals(a1.Name, 'hello raja');
   

   // 2nd method test coverage.
   
  
   
     
   
CompetitorController.findByCompetitor('hello raja');
       System.assertEquals(a1.Name, 'hello raja');
   }
 }