public class CaseResponseTime {
    @InvocableMethod (Label='Get First Response Duration')
    public static List<Decimal> getFirstResponseDuration(List<Id> caseIds) {
        List<Decimal> response = new List<Decimal>();
        for(Case cs : [SELECT BusinessHoursId, CreatedDate FROM Case WHERE Id IN :caseIds]) {
            response.add(Double.valueOf((BusinessHours.diff(cs.BusinessHoursId, cs.CreatedDate, system.now())) / (1000*60*60)));
        }
        return response;
    }
}