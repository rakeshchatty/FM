public without sharing class Duration {

	@TestVisible
	private static final Date KNOWN_SUNDAY = Date.newInstance(2023, 1, 1);

	public static Date toMonthEnd() {
		return toMonthEnd(System.today());
	}

	public static Date toMonthEnd(Date someDate) {
		return Date.newInstance(someDate.year(), someDate.month() + 1, 0);
	}

	public static Date toNextSunday() {
		return toNextSunday(System.today());
	}

	public static Date toNextSunday(Date someDate) {
		Integer daysAfterSunday = Math.mod(KNOWN_SUNDAY.daysBetween(someDate), 7);
		return someDate + (daysAfterSunday == 0 ? 0 : 7 - daysAfterSunday);
	}

	public static Date toTwiceMonthlyEnd() {
		return toTwiceMonthlyEnd(System.today());
	}

	public static Date toTwiceMonthlyEnd(Date someDate) {
		return (someDate.day() < 16) ? Date.newInstance(someDate.year(), someDate.month(), 15) : toMonthEnd(someDate);
	}
}