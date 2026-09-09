public class DeliveryRouting {
    
    public static void prepareRequest(Id deliveryOrderGroupId) {
        
        List<DeliveryOrder__c> deliveryOrders = [SELECT Order__r.Id, Order__r.OrderNumber, Order__r.AccountId, Order__r.Account.Name, Order__r.Account.BillingLongitude, Order__r.Account.BillingLatitude, OrderNumber__c, ServiceTime__c, Demand__c, ServiceType__c, SkillSet__c, DeliveryRoute__c, SequenceNumber__c, RouteDate__c, StreetSegmentID__c FROM DeliveryOrder__c WHERE DeliveryOrderGroup__c = :deliveryOrderGroupId];
        DeliveryRouteGroup__c deliveryRouteGroup = [SELECT Id from DeliveryRouteGroup__c ORDER BY CreatedDate Desc LIMIT 1];
        List<DeliveryRoute__c> deliveryRoutes = [SELECT Id, Name, StartTime__c, MaximumRouteTime__c, StartLocation__c, RtePref__c, VehicleCapacity__c, SkillSet__c FROM DeliveryRoute__c WHERE DeliveryRouteGroup__c =: deliveryRouteGroup.Id]; 
        List<Depot__c> depot = [SELECT Id, Name, Penalty__c, Score__c, StartEnd__c, AccessTime__c, Address__c, Address__Street__s, Address__City__s, Address__PostalCode__s, Address__latitude__s, Address__longitude__s, Address__StateCode__s, HasContainers__c,Duration__c,IsIntermediate__c, IsActive__c FROM Depot__c];
        Map<String, GlobalParameter__mdt> globalParameters = GlobalParameter__mdt.getAll();
        
        RaasDelivery raasPayload = new RaasDelivery();
        RaasDelivery.ParameterOverride parameterOverride = new RaasDelivery.ParameterOverride();
        List<RaasDelivery.Facility> facilities = new List<RaasDelivery.Facility>();
        List<RaasDelivery.ServiceLocation> serviceLocations = new List<RaasDelivery.ServiceLocation>();
        List<RaasDelivery.Route> routeSet = new List<RaasDelivery.Route>();
        
        parameterOverride.solver = globalParameters.get('DeliveryGlobalParameters').Solver__c;
        parameterOverride.generateMethod = globalParameters.get('DeliveryGlobalParameters').GenerateMethod__c;
        parameterOverride.numberOfRoutes = globalParameters.get('DeliveryGlobalParameters').NumberOfRoutes__c;
        parameterOverride.maxRouteTime = globalParameters.get('DeliveryGlobalParameters').MaxRouteTime__c;
        parameterOverride.startTime = globalParameters.get('DeliveryGlobalParameters').StartTime__c;
        parameterOverride.seqStart = globalParameters.get('DeliveryGlobalParameters').SeqStart__c;
        parameterOverride.seqGap = globalParameters.get('DeliveryGlobalParameters').SeqGap__c;
        parameterOverride.UseSpecialties = globalParameters.get('DeliveryGlobalParameters').UseSpecialties__c;
        parameterOverride.UsePickupDeliveryCapacity = globalParameters.get('DeliveryGlobalParameters').UsePickupDeliveryCapacity__c;
        parameterOverride.addextraRT = globalParameters.get('DeliveryGlobalParameters').AddExtraRT__c;
        
        for (Depot__c depots : depot) {
            RaasDelivery.Facility facility = new RaasDelivery.Facility();
            facility.name = depots.name;
            facility.score = depots.Score__c;
            facility.clientXCoord = depots.Address__Longitude__s;
            facility.clientYCoord = depots.Address__Latitude__s;
            facility.address = depots.Address__Street__s;
            facility.city = depots.Address__City__s;
            facility.zipCode = depots.Address__PostalCode__s;
            facility.startEnd = depots.StartEnd__c;
            facility.intermediate = depots.IsIntermediate__c;
            facility.penalty = depots.Penalty__c;
            facility.duration = depots.Duration__c;
            facility.accessTime = depots.AccessTime__c;
            facility.containers = depots.HasContainers__c;
            facility.isActive = depots.IsActive__c;
            facilities.add(facility);
        }
        
        for (DeliveryOrder__c deliveryOrder : deliveryOrders) {
            RaasDelivery.ServiceLocation serviceLocation = new RaasDelivery.ServiceLocation();
            serviceLocation.recordID = deliveryOrder.OrderNumber__c;
            serviceLocation.accountID = deliveryOrder.Order__r.AccountId;
            serviceLocation.customerName = deliveryOrder.Order__r.Account.Name;
            serviceLocation.address = '';
            serviceLocation.zipCode = '';
            serviceLocation.clientXCoord = deliveryOrder.Order__r.Account.BillingLongitude;
            serviceLocation.clientYCoord = deliveryOrder.Order__r.Account.BillingLatitude;
            serviceLocation.serviceType = deliveryOrder.ServiceType__c;
            serviceLocation.demand.add(deliveryOrder.Demand__c);
            serviceLocation.zonePriority = '';
            serviceLocation.earliestArrival = '';
            serviceLocation.latestArrival = '';
            serviceLocation.noServiceStart = '';
            serviceLocation.noServiceEnd = '';
            serviceLocation.region = '';
            serviceLocation.serviceType = deliveryOrder.ServiceType__c;
            serviceLocation.skillSetProperties.add(deliveryOrder.SkillSet__c);
            serviceLocation.existingSequence = 0;
            serviceLocation.prepTime = 0;
            serviceLocation.xCoord = 0;
            serviceLocation.yCoord = 0;
            serviceLocation.sequence = 0;
            serviceLocation.serviceSide = 0;
            serviceLocation.autoConnect = false;
            serviceLocation.deltaDistance = 0;
            serviceLocation.cumulativeDistance = 0;
            serviceLocation.tripNum = 0;
            serviceLocations.add(serviceLocation);
        }
        
        for(DeliveryRoute__c deliveryRoute : deliveryRoutes) {
            RaasDelivery.Route route = new RaasDelivery.Route();
            route.routeId = deliveryRoute.Name;
            route.startTime = deliveryRoute.StartTime__c;
            route.maxRouteTime = deliveryRoute.MaximumRouteTime__c;
            route.startLocation = deliveryRoute.StartLocation__c;
            route.rtePref = deliveryRoute.RtePref__c;
            route.vehicleCapacity.add(deliveryRoute.VehicleCapacity__c);
            route.skillSetProperties = deliveryRoute.SkillSet__c.split(',');
            routeSet.add(route);
        }
        
        raasPayload.parameterOverrides = parameterOverride;
        raasPayload.facilities = facilities;
        raasPayload.serviceLocations = serviceLocations;
        raasPayload.routeSet = routeSet;
        String jsonRaasPayload = JSON.serialize(raasPayload);
        sendRaasRequest(jsonRaasPayload, deliveryOrderGroupId);
    }
    
    @future (callout=true)
    public static void sendRaasRequest(String body, Id deliveryOrderGroupId) {
        DeliveryOrderGroup__c deliveryOrderGroup = [SELECT Id, Status__c, JobId__c, ErrorMessage__c, StatusUpdatedAt__c FROM DeliveryOrderGroup__c WHERE Id = :deliveryOrderGroupId];
        RaaS__c setting = RaaS__c.getOrgDefaults();
        String licenseId = setting.licenseId__c;    
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:RaaS/?licenseId=' + licenseId);
        req.setMethod('POST');
        req.setBody(body);
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            Map<String, String> responseBody = (Map<String, String>) JSON.deserialize(res.getBody(), Map<String, String>.class);
            if (res.getStatusCode() == 202) {
                deliveryOrderGroup.Status__c= 'Routing';
                deliveryOrderGroup.JobId__c = responseBody.get('jobId');
                deliveryOrderGroup.StatusUpdatedAt__c = System.now();
                Integer delayInMinutes = 1;
                ID jobID = System.enqueueJob(new RaasResponseQueueable(deliveryOrderGroup), delayInMinutes);
            }
            else {
                deliveryOrderGroup.Status__c = 'Error';
                deliveryOrderGroup.Errormessage__c = responseBody.get('errorMsg');
            }
        } catch (Exception e) {
            deliveryOrderGroup.Status__c = 'Error';
            deliveryOrderGroup.Errormessage__c = e.getMessage();
        }
        UPDATE deliveryOrderGroup;
    }
    
    @InvocableMethod (Label='Get RaaS Response')
    public static void getFullResponse(List<String> jobId) {
        DeliveryOrderGroup__c deliveryOrderGroup = [SELECT Id, Status__c, ErrorMessage__c, StatusUpdatedAt__c FROM DeliveryOrderGroup__c WHERE CreatedDate = TODAY AND JobId__c IN :jobId LIMIT 1];
        RaaS__c setting = RaaS__c.getOrgDefaults();
        String licenseId = setting.licenseId__c;
        String endpointUrl = 'callout:RaaS/' + jobId[0] + '?licenseId=' + licenseId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpointUrl);
        req.setMethod('GET');
        req.setHeader('Content-Type', 'application/json');
        Http http = new Http();
        try {
            HTTPResponse res = http.send(req);
            RaaSResponseWrapper raasResponse = (RaaSResponseWrapper) JSON.deserialize(res.getBody(), RaaSResponseWrapper.class);        
            if (res.getStatusCode() == 200 && raasResponse.status == 'Routing') {
                deliveryOrderGroup.Status__c = 'Routing';
                deliveryOrderGroup.StatusUpdatedAt__c = System.now();
            } else if(res.getStatusCode() == 200 && raasResponse.status == 'Complete') {
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
                deliveryOrderGroup.Status__c = 'Error';
                deliveryOrderGroup.Errormessage__c = raasResponse.errorMsg;
            }            
        } catch (Exception e) {
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