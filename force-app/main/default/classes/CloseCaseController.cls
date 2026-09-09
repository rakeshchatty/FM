public class CloseCaseController {
    @AuraEnabled
    public static Case RetreiveCase(Id caseId){
        system.debug('this is called::'+caseId);
        return([Select id, Status, isClosed From Case Where id=:caseId]);
    }
    @AuraEnabled
    public static Case saveCase(Case caseA){
        system.debug('case::'+caseA);
        caseA.Status = 'Closed';
        update caseA;
        return caseA;
    }
}