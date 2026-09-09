@isTest
public class SupplierProductTest {
    
     public static testmethod void UnitTestMethod1(){
         	
         Supplier_Product__c suppProd1 = new Supplier_Product__c(
             Name = 'testSuppProd1',
             Supplier_Price__c = 10,
             Start_Date__c = system.today() - 5,
             End_Date__c = system.today() + 5,
             Enqix_UID__c = '1233321'
         );   
         Database.SaveResult set1 = Database.insert(suppProd1, false); 
         system.assertEquals(set1.isSuccess(),true);
         suppProd1.Supplier_Price__c = 11;
         update suppProd1;
         
         Supplier_Product__c suppProd2 = new Supplier_Product__c(
             Name = 'testSuppProd2',
             Start_Date__c = system.today() - 5,
             End_Date__c = system.today(),
             Enqix_UID__c = '1233321'
         ); 
         Database.SaveResult set2 = Database.insert(suppProd2, false);
         system.assertEquals(set2.isSuccess(),false);
         
         Supplier_Product__c suppProd3 = new Supplier_Product__c(
             Name = 'testSuppProd3',
             Start_Date__c = system.today() -1,
             Enqix_UID__c = '1233321'
         ); 
         Database.SaveResult set3 = Database.insert(suppProd3, false);
         system.assertEquals(set3.isSuccess(),false);
         
         SupplierProductHelper sph = new SupplierProductHelper();
         sph.testBost();
     }

}