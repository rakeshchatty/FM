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

	public static Date toNextDay(Date startDate, String nextDay) {
		return startDate.addDays(Day.valueOf(nextDay).ordinal());
	}

	public static Date getNextWeekday(Date someDate) {
		Integer dayOfWeek = getDayOfWeek(someDate).ordinal();
		return dayOfWeek <= Day.Thursday.ordinal() ? someDate + 1 : someDate - dayOfWeek + 7;
	}

	private static Set<Date> getDates(Date startDate, Date endDate, Integer weekFrequency) {
		Integer daysToSkip = weekFrequency * 7;
		Date matchedDate = startDate;

		Set<Date> dates = new Set<Date>();
		while (matchedDate <= endDate) {
			dates.add(matchedDate);
			matchedDate += daysToSkip;
		}

		return dates;
	}

	private static Set<Date> getDates(Date startDate, Date endDate, Day dayOfWeek) {
		Date matchedDate = startDate;
		do {
			if (getDayOfWeek(matchedDate) == dayOfWeek) {
				return getDates(matchedDate, endDate, 1);
			} else {
				matchedDate += 1;
			}
		} while (matchedDate <= endDate);

		return new Set<Date>();
	}

	public static Set<Date> getDates(Date startDate, Date endDate, Day dayOfWeek, Integer weekFrequency, Date previousDate) {
		weekFrequency = weekFrequency ?? 1;
		if (startDate == null || endDate == null || startDate > endDate) {
			return new Set<Date>();
		}

		if (weekFrequency == 1) {
			return getDates(startDate, endDate, dayOfWeek);
		}

		Integer daysToSkip = weekFrequency * 7;
		Date matchedDate = previousDate;
		do {
			matchedDate += daysToSkip;
		} while (matchedDate < startDate);

		return getDates(matchedDate, endDate, weekFrequency);
	}
/*
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
*/
	@TestVisible
	private static Integer weeksApart(Date date1, Date date2) {
		Date startDate = date1 <= date2 ? date1 : date2;
		Date endDate = date1 > date2 ? date1 : date2;
		Integer startYear = startDate.year();
		Integer endYear = endDate.year();
		if (endYear > startYear) {
			return weeksApart(startDate, Date.newInstance(startYear, 12, 31)) + weeksApart(Date.newInstance(startYear + 1, 1, 1), endDate);
		}

		Integer weekOfStartDate = (startDate.dayOfYear() + 6) / 7;
		Integer weekOfEndDate = (endDate.dayOfYear() + 6) / 7;
		return weekOfEndDate - weekOfStartDate;
	}
}