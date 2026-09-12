public without sharing class Convert {

	public static Integer toInteger(Decimal value) {
		return (value == null) ? null : value.intValue();
	}

	public static Integer toInteger(String value) {
		return String.isBlank(value) ? null : Integer.valueOf(value);
	}

	public static Boolean toBoolean(String value) {
		return String.isBlank(value) ? null : Boolean.valueOf(value);
	}

	public static String toString(Integer value) {
		return (value == null) ? null : String.valueOf(value);
	}

	public static String toHhMm(Time value) {
		return (value == null) ? null : String.valueOf(value).left(5);
	}

	public static String toString(Date value, String format) {
		return (value == null || String.isBlank(format)) ? null : toString(DateTime.newInstance(value.year(), value.month(), value.day()), format);
	}

	public static String toString(DateTime value, String format) {
		return (value == null || String.isBlank(format)) ? null : value.format(format);
	}

	public static Time toTime(String value) {
		if (String.isBlank(value)) {return null;}

		String[] timeSplit = value.split(':');
		return Time.newInstance(Integer.valueOf(timeSplit[0]), Integer.valueOf(timeSplit[1]), 0, 0);
	}

	public static List<String> toList(String value, String splitBy) {
		return String.isBlank(value) ? null : value.trim().split(splitBy);
	}
}