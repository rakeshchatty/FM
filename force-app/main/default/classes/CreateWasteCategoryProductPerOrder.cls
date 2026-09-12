public without sharing class CreateWasteCategoryProductPerOrder {
    
    private static final String HAZARDOUS_PRODUCT = 'Hazardous Consignment Note';
    
    @InvocableMethod(label='Create Waste Category Product Per Order' category='Compliance Document')
    public static void create(List<Input> inputs) {
        Set<Id> orderIds = new Set<Id>();
        for (Input input : inputs) {
            orderIds.add(input.orderId);
        }
        
        Map<Id, List<OrderItem>> orderWithOrderProducts = new Map<Id,  List<OrderItem>>();
        Map<String, Decimal> orderProductWeightMap = new Map<String, Decimal>();
        List<OrderItem> orderProducts = [SELECT OrderId, Product2Id, WTNProduct__c,Total_KG__c,Total_KG_Order_Line__c FROM OrderItem WHERE OrderId IN :orderIds];
        for (OrderItem orderProduct : orderProducts) {
            String key = generateKey(orderProduct);
            if (!orderWithOrderProducts.containsKey(orderProduct.OrderId)) {
                orderWithOrderProducts.put(orderProduct.OrderId, new  List<OrderItem>());
            }
            orderWithOrderProducts.get(orderProduct.OrderId).add(orderProduct);
            
            if (orderProduct.WTNProduct__c == HAZARDOUS_PRODUCT) {
                Decimal currentWeight = orderProduct.Total_KG__c != null ? orderProduct.Total_KG__c : orderProduct.Total_KG_Order_Line__c;
                Decimal totalWeight = orderProductWeightMap.get(key) ?? 0;
                if (currentWeight > 0) {
                    orderProductWeightMap.put(key,totalWeight + currentWeight);
                }
            }
        }
        
        List<CreateWasteCategoryProduct.Input> createWasteCategoryProducts = new List<CreateWasteCategoryProduct.Input>();
        for (Input input : inputs) {
            for (OrderItem orderItem : orderWithOrderProducts.get(input.orderId)) {
                if (orderItem.WTNProduct__c != input.wtnProduct) {
                    continue;
                }
                String key = generateKey(orderItem);
                CreateWasteCategoryProduct.Input createWasteCategoryProduct = new CreateWasteCategoryProduct.Input();
                createWasteCategoryProduct.complianceDocumentId = input.complianceDocumentId;
                createWasteCategoryProduct.productId = orderItem.Product2Id;
                if (input.wtnProduct == HAZARDOUS_PRODUCT) {
                    createWasteCategoryProduct.weight = orderProductWeightMap.get(key);
                }
                createWasteCategoryProducts.add(createWasteCategoryProduct);
            }
        }
        CreateWasteCategoryProduct.create(createWasteCategoryProducts);
    }
    
    private static String generateKey(OrderItem orderItem) {
        return orderItem.OrderId + '-' + orderItem.Product2Id;
    }
    
    public class Input {
        @InvocableVariable(required=true)
        public String complianceDocumentId, orderId, wtnProduct;
    }
}