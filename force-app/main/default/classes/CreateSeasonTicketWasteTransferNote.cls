public without sharing class CreateSeasonTicketWasteTransferNote {

    @InvocableMethod(label='Create Season Ticket Waste Transfer Note' category='WTN')
    public static List<Id> create(List<Input> inputs) {
        Map<String, Compliance_Doc__c> wtnMap = new Map<String, Compliance_Doc__c>();
        for (Input input : inputs) {
            String key = generateKey(input);
            if (!wtnMap.containsKey(key)) {
                wtnMap.put(key, prepare(input));
            }
        }
        INSERT wtnMap.values();

        // output should match the input size
        List<Id> wtnIds = new List<Id>();
        for (Input input : Inputs) {
            wtnIds.add(wtnMap.get(generateKey(input)).Id);
        }
        return wtnIds;
    }

    private static String generateKey(Input input) {
        return input.locationId + '-' + input.supplierId;
    }

    private static Compliance_Doc__c prepare(Input input) {
        Map<String, Object> params = new Map<String, Object>();
        params.put('LocationId',  input.locationId);
        params.put('SupplierId', input.supplierId);
        params.put('IsSeasonTicket', true);
        params.put('StartDate', input.startDate);

        Flow.Interview.ComplianceDocumentCreate createWTN = new Flow.Interview.ComplianceDocumentCreate(params);
        createWTN.start();
        return createWTN.ComplianceDocument;
    }
    
    public class Input {
        @InvocableVariable(required=true)
        public String locationId, supplierId;
        
        @InvocableVariable(required=true)
        public Date startDate;
    }
}