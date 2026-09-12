public without sharing class CreateWasteCategoryProduct {
    
    @InvocableMethod(label='Create Waste Category Product' category='Compliance Document')
    public static void create(List<Input> inputs) {
        Map<String, WTN_Waste_Category__c> wtnWasteCategoryMap = new Map<String, WTN_Waste_Category__c>();
        for (Input input : inputs) {
            String key = generateKey(input);
            if (!wtnWasteCategoryMap.containsKey(key)) {
                wtnWasteCategoryMap.put(key, prepare(input));
            }
        }
        INSERT wtnWasteCategoryMap.values();
    }
    
    private static String generateKey(Input input) {
        return input.complianceDocumentId + '-' + input.productId;
    }
    
    private static WTN_Waste_Category__c prepare(Input input) {
        Map<String, Object> params = new Map<String, Object>();
        params.put('ProductId', input.productId);
        params.put('ComplianceDocumentId', input.complianceDocumentId);
        params.put('Weight', input.weight);
        
        Flow.Interview.ComplianceDocumentWtnWasteCategoryCreate createWTNProduct = new Flow.Interview.ComplianceDocumentWtnWasteCategoryCreate(params);
        createWTNProduct.start();
        return createWTNProduct.WTNWasteCategory;
    }
    
    public class Input {
        @InvocableVariable(required=true)
        public String complianceDocumentId, productId;
        @InvocableVariable 
        public Decimal weight;
    }
}