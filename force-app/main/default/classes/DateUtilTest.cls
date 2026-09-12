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
	static void getDates() {
		//Checking Mondays within 4 weeks starting from Monday
		Date startDate = Date.newInstance(2026, 6, 1);
		Date endDate = Date.newInstance(2026, 6, 30);
		Assert.areEqual(5, DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 1, null).size());

		//Checking Mondays within 4 weeks starting from Tuesday
		Assert.areEqual(4, DateUtil.getDates(startDate.addDays(1), endDate, DateUtil.Day.Monday, 1, null).size());

		//Fortnightly with start week as week off
		Assert.areEqual(3, DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 2, startDate.addDays(-14)).size());

		//Fortnightly with start week as not week off
		Assert.areEqual(2, DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 2, startDate.addDays(-7)).size());

		Assert.areEqual(10, DateUtil.weeksApart(startDate, startDate.addDays(70)));
	}

	@isTest
	static void getDatesWeekFrequency1() {
		Date startDate = Date.newInstance(2026, 6, 1);
		Date endDate = Date.newInstance(2026, 6, 30);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 1, null);
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 8)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 15)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 22)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 29)));

		dates = DateUtil.getDates(startDate, startDate, DateUtil.Day.Monday, 1, null);
		Assert.areEqual(1, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 1)));

		dates = DateUtil.getDates(startDate, startDate, DateUtil.Day.Tuesday, 1, null);
		Assert.areEqual(0, dates.size());
	}

	@isTest
	static void getDatesWeekFrequency2() {
		Date startDate = Date.newInstance(2026, 6, 1);
		Date endDate = Date.newInstance(2026, 7, 31);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 2, Date.newInstance(2026, 5, 18));
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 15)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 29)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 13)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 27)));

		dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 2, Date.newInstance(2026, 5, 11));
		Assert.areEqual(4, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 8)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 22)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 6)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 20)));
	}

	@isTest
	static void getDatesWeekFrequency3() {
		Date startDate = Date.newInstance(2026, 6, 1);
		Date endDate = Date.newInstance(2026, 8, 31);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 3, Date.newInstance(2026, 5, 11));
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 22)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 13)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 3)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 24)));

		dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 3, Date.newInstance(2026, 5, 18));
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 8)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 29)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 20)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 10)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 31)));
	}

	@isTest
	static void getDatesWeekFrequency4() {
		Date startDate = Date.newInstance(2026, 6, 1);
		Date endDate = Date.newInstance(2026, 9, 30);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 4, Date.newInstance(2026, 5, 4));
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 29)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 27)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 24)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 9, 21)));

		dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 4, Date.newInstance(2026, 5, 11));
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 8)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 6)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 3)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 8, 31)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 9, 28)));
	}

	@isTest
	static void getDatesWeekFrequency26() {
		Date startDate = Date.newInstance(2026, 1, 1);
		Date endDate = Date.newInstance(2026, 12, 31);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Thursday, 26, Date.newInstance(2025, 7, 3));
		Assert.areEqual(3, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 1, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 2)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 12, 31)));
	}

	@isTest
	static void getDatesWeekFrequency52() {
		Date startDate = Date.newInstance(2026, 1, 1);
		Date endDate = Date.newInstance(2026, 12, 31);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Thursday, 52, Date.newInstance(2025, 1, 2));
		Assert.areEqual(2, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 1, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 12, 31)));
	}

	@isTest
	static void getDatesInvalidRange() {
		Set<Date> dates = DateUtil.getDates(Date.today(), Date.today().addDays(-1), DateUtil.Day.Monday, 1, null);
		Assert.areEqual(0, dates.size());

		dates = DateUtil.getDates(Date.today(), null, DateUtil.Day.Monday, 1, null);
		Assert.areEqual(0, dates.size());

		dates = DateUtil.getDates(null, Date.today(), DateUtil.Day.Monday, 1, null);
		Assert.areEqual(0, dates.size());
	}

	@isTest
	static void getDatesWhenPreviousCollectionDateIsFarInPast() {
		Date startDate = Date.newInstance(2026, 6, 1);
		Date endDate = Date.newInstance(2026, 7, 31);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 2, Date.newInstance(2026, 1, 12));
		Assert.areEqual(5, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 1)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 15)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 29)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 13)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 7, 27)));
	}

	@isTest
	static void getDatesWhenStartDateDoesNotMatchDayOfWeek() {
		Date startDate = Date.newInstance(2026, 6, 2);
		Date endDate = Date.newInstance(2026, 6, 30);

		Set<Date> dates = DateUtil.getDates(startDate, endDate, DateUtil.Day.Monday, 1, null);
		Assert.areEqual(4, dates.size());
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 8)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 15)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 22)));
		Assert.isTrue(dates.contains(Date.newInstance(2026, 6, 29)));
	}

	@isTest
	static void toNextDay() {
		Date startDate = Date.newInstance(2026, 6, 1);

		Assert.areEqual(startDate, DateUtil.toNextDay(startDate, 'Monday'));
		Assert.areEqual(startDate + 1, DateUtil.toNextDay(startDate, 'Tuesday'));
		Assert.areEqual(startDate + 6, DateUtil.toNextDay(startDate, 'Sunday'));
	}
}