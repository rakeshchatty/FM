public class RaasResponseQueueable implements Queueable, Database.AllowsCallouts {
    public DeliveryOrderGroup__c deliveryOrderGroup;

    public RaasResponseQueueable(DeliveryOrderGroup__c deliveryOrderGroup) {
        this.deliveryOrderGroup = deliveryOrderGroup;
    }

    public void execute(QueueableContext context) {
        RaaS__c setting = RaaS__c.getOrgDefaults();
        String licenseId = setting.licenseId__c;
        String endpointUrl = 'callout:RaaS/' + deliveryOrderGroup.JobId__c + '?licenseId=' + licenseId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        try {
            HTTPResponse res = http.send(req);
            RaaSResponseWrapper raasResponse = (RaaSResponseWrapper) JSON.deserialize(res.getBody(), RaaSResponseWrapper.class);
            if (res.getStatusCode() == 200 && raasResponse.status == 'Routing') {
                System.debug('routing');
                Integer delayInMinutes = 1;
                ID jobID = System.enqueueJob(new RaasResponseQueueable(deliveryOrderGroup), delayInMinutes);
            } else if(res.getStatusCode() == 200 && raasResponse.status == 'Complete') {
                System.debug('completed');
                deliveryOrderGroup.Status__c = 'Sequence Completed';
                Map<Integer, DeliveryOrder__c> locationSequenceMap = mapDeliveryOrders([SELECT Id, OrderNumber__c, SequenceNumber__c, DeliveryRoute__c FROM DeliveryOrder__c WHERE DeliveryOrderGroup__c = :deliveryOrderGroup.Id]);
                Map<String, DeliveryRoute__c> routeNameMap = mapDeliveryRoutes([SELECT Id, Name FROM DeliveryRoute__c WHERE CreatedDate = TODAY]);
                for (ServiceLocation location : raasResponse.serviceLocations) {
                    if (locationSequenceMap.containsKey(location.recordID)) {
                        locationSequenceMap.get(location.recordID).SequenceNumber__c = location.sequence;
                        locationSequenceMap.get(location.recordID).DeliveryRoute__c = routeNameMap.get(location.route).Id;
                    }
                }
                UPDATE locationSequenceMap.values();
            }
            else {
                System.debug('else');
                deliveryOrderGroup.Status__c = 'Error';
                deliveryOrderGroup.Errormessage__c = raasResponse.errorMsg;
            }            
        } catch (Exception e) {
            System.debug('exception');
            deliveryOrderGroup.Status__c = 'Error';
            deliveryOrderGroup.Errormessage__c = e.getMessage();           
        }
        
        UPDATE deliveryOrderGroup;
    }

    public static Map<String, DeliveryRoute__c> mapDeliveryRoutes(List<DeliveryRoute__c> deliveryRoutes) {
        Map<String, DeliveryRoute__c> routeNameMap = new Map<String, DeliveryRoute__c>();
        for (DeliveryRoute__c deliveryRoute : deliveryRoutes) {
            routeNameMap.put(deliveryRoute.Name, deliveryRoute);
        }
        return routeNameMap;
    }
    
    public static Map<Integer, DeliveryOrder__c> mapDeliveryOrders(List<DeliveryOrder__c> deliveryOrders) {
        Map<Integer, DeliveryOrder__c> locationSequenceMap = new Map<Integer, DeliveryOrder__c>();
        for (DeliveryOrder__c deliveryOrder : deliveryOrders) {
            if (deliveryOrder.OrderNumber__c != null) {
                locationSequenceMap.put(Integer.valueOf(deliveryOrder.OrderNumber__c), deliveryOrder);
            }
        }
        return locationSequenceMap;
    }

    public class RaasResponseWrapper {
        public Integer jobId;
        public String status;
        public String errorMsg;
        public List<ServiceLocation> serviceLocations;
    }
    
    public class ServiceLocation {
        public Integer recordID;
        public String route;
        public Integer sequence;
    }

}