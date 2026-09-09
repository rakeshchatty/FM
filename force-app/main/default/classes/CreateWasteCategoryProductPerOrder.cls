public without sharing class CreateWasteCategoryProductPerOrder {
    
    @InvocableMethod(label='Create Waste Category Product Per Order' category='Compliance Document')
    public static void create(List<Input> inputs) {
        Set<Id> orderIds = new Set<Id>();
        for (Input input : inputs) {
            orderIds.add(input.orderId);
        }
        
        Map<Id, List<OrderItem>> orderWithOrderProducts = new Map<Id,  List<OrderItem>>();
        List<OrderItem> orderProducts = [SELECT OrderId, Product2Id, WTNProduct__c FROM OrderItem WHERE OrderId IN :orderIds];
        for (OrderItem orderProduct : orderProducts) {
            String key = generateKey(orderProduct);
            if (!orderWithOrderProducts.containsKey(orderProduct.OrderId)) {
                orderWithOrderProducts.put(orderProduct.OrderId, new  List<OrderItem>());
            }
            orderWithOrderProducts.get(orderProduct.OrderId).add(orderProduct);
        }
        
        List<CreateWasteCategoryProduct.Input> createWasteCategoryProducts = new List<CreateWasteCategoryProduct.Input>();
        for (Input input : inputs) {
            for (OrderItem orderItem : orderWithOrderProducts.get(input.orderId)) {
                if (orderItem.WTNProduct__c != input.wtnProduct) {
                    continue;
                }
                CreateWasteCategoryProduct.Input createWasteCategoryProduct = new CreateWasteCategoryProduct.Input();
                createWasteCategoryProduct.complianceDocumentId = input.complianceDocumentId;
                createWasteCategoryProduct.productId = orderItem.Product2Id;
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