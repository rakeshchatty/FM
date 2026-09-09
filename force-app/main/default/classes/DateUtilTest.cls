@isTest
private class DateUtilTest {

	@isTest
	static void getNextWeekday() {
		Date monday = Date.newInstance(2024, 01, 01);
		Assert.areEqual(monday + 1, DateUtil.getNextWeekday(monday));
		Assert.areEqual(monday + 2, DateUtil.getNextWeekday(monday + 1));
		Assert.areEqual(monday + 3, DateUtil.getNextWeekday(monday + 2));
		Assert.areEqual(monday + 4, DateUtil.getNextWeekday(monday + 3));
		Assert.areEqual(monday + 7, DateUtil.getNextWeekday(monday + 4));
		Assert.areEqual(monday + 7, DateUtil.getNextWeekday(monday + 5));
		Assert.areEqual(monday + 7, DateUtil.getNextWeekday(monday + 6));
	}

	@isTest
	static void countDays() {
		Date monday = Date.newInstance(2024, 01, 01);
		String mondayString = DateUtil.Day.Monday.name();
		Assert.areEqual(1, DateUtil.countDays(monday, monday + 00, mondayString, null, null));
		Assert.areEqual(1, DateUtil.countDays(monday, monday + 01, mondayString, null, null));
		Assert.areEqual(1, DateUtil.countDays(monday, monday + 02, mondayString, null, null));
		Assert.areEqual(1, DateUtil.countDays(monday, monday + 06, mondayString, null, null));

		Assert.areEqual(2, DateUtil.countDays(monday, monday + 07, mondayString, null, null));
		Assert.areEqual(2, DateUtil.countDays(monday, monday + 08, mondayString, null, null));
		Assert.areEqual(2, DateUtil.countDays(monday, monday + 13, mondayString, null, null));

		Assert.areEqual(3, DateUtil.countDays(monday, monday + 14, mondayString, null, null));
		Assert.areEqual(4, DateUtil.countDays(monday, monday + 21, mondayString, null, null));
		Assert.areEqual(6, DateUtil.countDays(monday, monday + 35, mondayString, null, null));

		Assert.areEqual(53, DateUtil.countDays(monday, monday + 365, mondayString, null, null));

		Assert.areEqual(0, DateUtil.countDays(monday, monday + 00, mondayString, monday, monday));
		Assert.areEqual(1, DateUtil.countDays(monday, monday + 07, mondayString, monday, monday));
		Assert.areEqual(1, DateUtil.countDays(monday, monday + 07, mondayString, monday, monday + 01));
		Assert.areEqual(0, DateUtil.countDays(monday, monday + 07, mondayString, monday, monday + 07));

		Assert.areEqual(49, DateUtil.countDays(monday, monday + 365, mondayString, monday + 13, monday + 36));
	}
}