@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.CognitiveComplexity')
@isTest
private class DurationTest {

	@isTest
	static void toMonthEnd() {
		Assert.areEqual(Date.newInstance(2023, 01, 31), Duration.toMonthEnd(Date.newInstance(2023, 01, 01)));
		Assert.areEqual(Date.newInstance(2023, 01, 31), Duration.toMonthEnd(Date.newInstance(2023, 01, 10)));

		Assert.areEqual(Date.newInstance(2023, 02, 28), Duration.toMonthEnd(Date.newInstance(2023, 02, 01)));
		Assert.areEqual(Date.newInstance(2023, 02, 28), Duration.toMonthEnd(Date.newInstance(2023, 02, 10)));

		Assert.areEqual(Date.newInstance(2024, 02, 29), Duration.toMonthEnd(Date.newInstance(2024, 02, 01)));
		Assert.areEqual(Date.newInstance(2024, 02, 29), Duration.toMonthEnd(Date.newInstance(2024, 02, 10)));

		Assert.areEqual(Date.newInstance(2023, 04, 30), Duration.toMonthEnd(Date.newInstance(2023, 04, 01)));
		Assert.areEqual(Date.newInstance(2023, 04, 30), Duration.toMonthEnd(Date.newInstance(2023, 04, 10)));
	}

	@isTest
	static void toTwiceMonthlyEnd() {
		Assert.areEqual(Date.newInstance(2023, 01, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 01, 01)));
		Assert.areEqual(Date.newInstance(2023, 01, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 01, 15)));
		Assert.areEqual(Date.newInstance(2023, 01, 31), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 01, 16)));
		Assert.areEqual(Date.newInstance(2023, 01, 31), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 01, 30)));
		Assert.areEqual(Date.newInstance(2023, 01, 31), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 01, 31)));

		Assert.areEqual(Date.newInstance(2023, 02, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 02, 01)));
		Assert.areEqual(Date.newInstance(2023, 02, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 02, 15)));
		Assert.areEqual(Date.newInstance(2023, 02, 28), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 02, 16)));
		Assert.areEqual(Date.newInstance(2023, 02, 28), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 02, 27)));
		Assert.areEqual(Date.newInstance(2023, 02, 28), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 02, 28)));

		Assert.areEqual(Date.newInstance(2024, 02, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2024, 02, 01)));
		Assert.areEqual(Date.newInstance(2024, 02, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2024, 02, 15)));
		Assert.areEqual(Date.newInstance(2024, 02, 29), Duration.toTwiceMonthlyEnd(Date.newInstance(2024, 02, 16)));
		Assert.areEqual(Date.newInstance(2024, 02, 29), Duration.toTwiceMonthlyEnd(Date.newInstance(2024, 02, 28)));
		Assert.areEqual(Date.newInstance(2024, 02, 29), Duration.toTwiceMonthlyEnd(Date.newInstance(2024, 02, 29)));

		Assert.areEqual(Date.newInstance(2023, 04, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 04, 01)));
		Assert.areEqual(Date.newInstance(2023, 04, 15), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 04, 15)));
		Assert.areEqual(Date.newInstance(2023, 04, 30), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 04, 16)));
		Assert.areEqual(Date.newInstance(2023, 04, 30), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 04, 29)));
		Assert.areEqual(Date.newInstance(2023, 04, 30), Duration.toTwiceMonthlyEnd(Date.newInstance(2023, 04, 30)));
	}

	@isTest
	static void toNextSunday() {
		Assert.areEqual(Duration.KNOWN_SUNDAY + 00, Duration.toNextSunday(Duration.KNOWN_SUNDAY + 0));	// Sunday
		Assert.areEqual(Duration.KNOWN_SUNDAY + 07, Duration.toNextSunday(Duration.KNOWN_SUNDAY + 1));	// Monday
		Assert.areEqual(Duration.KNOWN_SUNDAY + 07, Duration.toNextSunday(Duration.KNOWN_SUNDAY + 6));	// Saturday
		Assert.areEqual(Duration.KNOWN_SUNDAY + 07, Duration.toNextSunday(Duration.KNOWN_SUNDAY + 7));	// Sunday
		Assert.areEqual(Duration.KNOWN_SUNDAY + 14, Duration.toNextSunday(Duration.KNOWN_SUNDAY + 8));	// Monday
	}
}