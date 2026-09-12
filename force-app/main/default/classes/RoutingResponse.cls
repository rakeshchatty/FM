public without sharing class RoutingResponse {

	public Integer jobId;
	public String status;
	public String errorMsg;
	public List<Summary> routeSummary;
	public List<ServiceLocation> serviceLocations;

	public class ServiceLocation {
		public Integer recordID;
		public String route;
		public Integer sequence;
	}

	public class Summary {
		public String routeId;
		public String startTime;
		public String endTime;
		public String totalTime;
		public String travelTime;
		public String serviceTime;
		public String waitTime;
		public String extraTime;
		public String breakTime;
		public String facilityTime;
		public Integer startLocation;
		public String startLocationName;
		public Integer endLocation;
		public String endLocationName;
		public Decimal demand;
		public Integer geocodedLocations;
		public Integer unGeocodedLocations;
		public Integer sequencedLocations;
		public Integer unSequencedLocations;
		public Integer totalServiceLocations;
		public Decimal distance;
		public Decimal startStemDistance;
		public Decimal endStemDistance;
		public Decimal totalStemDistance;
	}
}