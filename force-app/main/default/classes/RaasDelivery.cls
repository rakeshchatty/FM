public with sharing class RaasDelivery {
    
    public ParameterOverride parameterOverrides;
    public List<Facility> facilities = new List<Facility>();
    public List<ServiceLocation> serviceLocations = new List<ServiceLocation>();
    public List<Route> routeSet = new List<Route>();

    public class ParameterOverride {
        public String solver;
        public String generateMethod;
        public String targetTime;
        public String numberOfRoutes;
        public Integer numDemandFields;
        public String maxRouteTime;
        public String startTime;
        public String startLocation;
        public String endLocation;
        public Integer preStartTime;
        public Integer postEndTime;
        public Integer startRouteNumber;
        public Integer routeNumberIncr;
        public Decimal seqStart;
        public Decimal seqGap;
        public String solName;
        public String solLabel;
        public Integer useBuilding;
        public Integer useBlockSeq;
        public Integer useFixedUnitSeq;
        public Integer useExtraDistance;
        public Integer useExtraTime;
        public Integer usePrepTime;
        public Integer bgnEndRouteTime_atFacility;
        public Integer inclRoutePrepTime;
        public Integer useRegions;
        public Integer useSectors;
        public Decimal UseSpecialties;
        public Integer useZonePriority;
        public Integer includeMeanderPenalty;
        public Decimal UsePickupDeliveryCapacity;
        public Decimal PickupCapacityPercentage;
        public Integer PickupDeliveryNumStacked;
        public Integer MixedMode;
        public Decimal MAWTBC;
        public Integer ParkAndLoop;
        public Decimal MaxLoopDemand;
        public Decimal MaxLoopTime;
        public Integer LoopParkOpt;
        public Decimal addextraRT;          
    }
    
    public class Facility {
        public Integer id;
        public String name;
        public String status;
        public Decimal score;
        public Decimal clientXCoord;
        public Decimal clientYCoord;
        public String clientSegmentID;
        public String clientSide;
        public String segmentId;
        public String side;
        public String address;
        public String city;
        public String zipCode;
        public String plus4;
        public String state;
        public String startEndID;
        public Boolean startEnd;
        public Boolean intermediate;
        public Decimal penalty;
        public Decimal duration;
        public Decimal accessTime;
        public String material;
        public Boolean containers;
        public String streetPreType;
        public String earliestArrival;
        public String latestArrival;
        public String matchCode;
        public Boolean isActive;
    }

    public class ServiceLocation {
        public Decimal recordID;
        public Id accountID;
        public String customerName;
        public String address;
        public String zipCode;
        public Decimal clientXCoord;
        public Decimal clientYCoord;
        public Decimal serviceTime;
        public List<Decimal> demand = new List<Decimal>();
        public String zonePriority;
        public String earliestArrival;
        public String latestArrival;
        public String noServiceStart;
        public String noServiceEnd;
        public String region;
        public String serviceType;
        public List<String> skillSetProperties = new List<String>();
        public Integer existingSequence;
        public Integer prepTime;
        public String serviceMode;
        public String matchCode;
        public Decimal xCoord;
        public Decimal yCoord;
        public String route;
        public Integer sequence;
        public String arrivalTime;
        public Integer serviceSide;
        public String waitTime;
        public Boolean autoConnect;
        public String deltaTime;
        public String cumulativeTime;
        public Decimal deltaDistance;
        public Decimal cumulativeDistance;
        public Integer tripNum;
        public String existingRoute;
    }

    public class Route {
        public String routeId;
        public String startTime;
        public String maxRouteTime;
        public List<Decimal> vehicleCapacity = new List<Decimal>();
        public Decimal startLocation;
        public Decimal rtePref;
        public List<String> skillSetProperties = new List<String>();
    }  
}