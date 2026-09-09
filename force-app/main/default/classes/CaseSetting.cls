public class CaseSetting {
	public static Integer getReopenDuration() {
		Decimal reopenDuration = CaseSetting__c.getOrgDefaults().ReopenDuration__c;
		return reopenDuration != null ? reopenDuration.intValue() : 7;
	}
}