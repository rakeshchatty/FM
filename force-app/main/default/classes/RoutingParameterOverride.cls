public without sharing class RoutingParameterOverride {

	public static RoutingParameterOverride__mdt get(String developerName ) {
		return Test.isRunningTest() ? TestDataHelper.getRoutingOverrides(developerName) : RoutingParameterOverride__mdt.getInstance(developerName).clone();
	}
}