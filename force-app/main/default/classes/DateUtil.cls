public without sharing class DateUtil {

	private static final Date MONDAY = Date.newInstance(2024, 01, 01);

	public enum Day {
		Monday, Tuesday, Wednesday, Thursday, Friday, Saturday, Sunday
	}

	public static Day getDayOfWeek(Date someDate) {
		Integer dayOfWeek = Math.mod(MONDAY.daysBetween(someDate), 7);	// MON = 0, TUE = 1, WED = 2, THU = 3, FRI = 4, SAT = 5, SUN = 6
		switch on dayOfWeek {
			when 0 {return Day.Monday;}
			when 1 {return Day.Tuesday;}
			when 2 {return Day.Wednesday;}
			when 3 {return Day.Thursday;}
			when 4 {return Day.Friday;}
			when 5 {return Day.Saturday;}
			when else {return Day.Sunday;}
		}
	}

	public static Date getNextWeekday(Date someDate) {
		Integer dayOfWeek = getDayOfWeek(someDate).ordinal();
		return dayOfWeek <= Day.Thursday.ordinal() ? someDate + 1 : someDate - dayOfWeek + 7;
	}

	public static Integer countDays(Date startDate, Date endDate, Day dayOfWeek) {
		if (startDate == null || endDate == null || startDate > endDate) {
			return 0;
		}

		Integer totalDays = startDate.daysBetween(endDate + 1);
		Integer dayCount = totalDays / 7;
		Integer remainingDays = Math.mod(totalDays, 7);
		if (remainingDays == 0) {
			return dayCount;
		}

		Integer startDayIndex = getDayOfWeek(startDate).ordinal();
		Integer endDayIndex = getDayOfWeek(endDate).ordinal();
		Integer dayOfWeekIndex = dayOfWeek.ordinal();
		if (startDayIndex <= endDayIndex) {	// E.g. Start = Tues, End = Sat
			return startDayIndex <= dayOfWeekIndex && dayOfWeekIndex <= endDayIndex ? dayCount + 1 : dayCount;
		} else {	// E.g. Start = Fri, End = Tue
			return startDayIndex <= dayOfWeekIndex || dayOfWeekIndex <= endDayIndex ? dayCount + 1 : dayCount;
		}
	}

	public static Integer countDays(Date startDate, Date endDate, String dayOfWeek, Date startExclusionDate, Date endExclusionDate) {
		Day day = Day.valueOf(dayOfWeek);
		return countDays(startDate, endDate, day) - countDays(startExclusionDate, endExclusionDate, day);
	}

	public static Date getQuarterStartDate(Date someDate) {
		Integer month = someDate.month();
		if (month <= 3) {
			return Date.newInstance(someDate.year(), 1, 1);
		} else if (month <= 6) {
			return Date.newInstance(someDate.year(), 4, 1);
		} else if (month <= 9) {
			return Date.newInstance(someDate.year(), 7, 1);
		} else {
			return Date.newInstance(someDate.year(), 10, 1);
		}
	}

	public static Date getQuarterEndDate(Date someDate) {
		Integer month = someDate.month();
		if (month <= 3) {
			return Date.newInstance(someDate.year(), 3, 31);
		} else if (month <= 6) {
			return Date.newInstance(someDate.year(), 6, 30);
		} else if (month <= 9) {
			return Date.newInstance(someDate.year(), 9, 30);
		} else {
			return Date.newInstance(someDate.year(), 12, 31);
		}
	}
}