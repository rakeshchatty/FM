@isTest
private class ConvertTest {

	@isTest
	static void conversions() {
		Decimal decimalValue = null;
		Assert.areEqual(null, Convert.toInteger(decimalValue));
		Assert.areEqual(11, Convert.toInteger(11.00));
		Assert.areEqual(12, Convert.toInteger(12.25));

		String stringValue = null;
		Assert.areEqual(null, Convert.toInteger(stringValue));
		Assert.areEqual(11, Convert.toInteger('11'));

		Assert.areEqual(null, Convert.toBoolean(stringValue));
		Assert.areEqual(false, Convert.toBoolean('11.00'));
		Assert.areEqual(false, Convert.toBoolean('false'));
		Assert.areEqual(true, Convert.toBoolean('true'));

		Integer integerValue = null;
		Assert.areEqual(null, Convert.toString(integerValue));
		Assert.areEqual('11', Convert.toString(11));

		Time timeValue = null;
		Assert.areEqual(null, Convert.toHhMm(timeValue));
		Assert.areEqual('23:58', Convert.toHhMm(Time.newInstance(23, 58, 59, 999)));

		Assert.areEqual(null, Convert.toTime(null));
		Assert.areEqual(null, Convert.toTime(''));
		Assert.areEqual(null, Convert.toTime(' '));
		Assert.areEqual(Time.newInstance(23, 58, 0, 0), Convert.toTime('23:58'));

		Assert.areEqual(null, Convert.toList(stringValue, ','));
		List<String> stringList = Convert.toList('A,B,C', ',');
		Assert.areEqual(3, stringList.size());

		DateTime someDateTime;
		Assert.areEqual(null, Convert.toString(someDateTime, 'yyyyMMdd'));
		someDateTime = DateTime.newInstance(2025, 05, 12, 17, 18, 19);
		Assert.areEqual(null, Convert.toString(someDateTime, null));
		Assert.areEqual(null, Convert.toString(someDateTime, ''));
		Assert.areEqual('20250512', Convert.toString(someDateTime, 'yyyyMMdd'));

		Date someDate;
		Assert.areEqual(null, Convert.toString(someDate, 'yyyyMMdd'));
		someDate = Date.newInstance(2025, 05, 13);
		Assert.areEqual(null, Convert.toString(someDate, null));
		Assert.areEqual(null, Convert.toString(someDate, ''));
		Assert.areEqual('20250513', Convert.toString(someDate, 'yyyyMMdd'));
	}
}