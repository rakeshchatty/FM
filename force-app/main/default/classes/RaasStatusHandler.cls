public class RaasStatusHandler {
    
    @InvocableMethod (label='Process Request')
    public static void raasStatus (List<String> jobId) {
        for (String DeliveryOrderGroupJobId : jobId) {
            DeliveryRouting.getFullResponse(DeliveryOrderGroupJobId);
        }        
    }
}