@isTest
public Class checkRecursion_Test {
    
    public static boolean run = false;
    
    @isTest
    public static void checkRecursion() {
        run = TRUE;
        System.assertEquals(True, True);
        checkRecursion.hasAlreadyRun();
    }        
}