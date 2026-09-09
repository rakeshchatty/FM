@isTest
private class IdUtilTest {

	@isTest
    static void isOrder() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);
		Order order = TestDataHelper.insertOrder(location.Id);

		Assert.isTrue(IdUtil.isOrder(order.Id));
		Assert.isFalse(IdUtil.isOrder(location.Id));
		Assert.isFalse(IdUtil.isOrder('ABC'));
		Assert.isFalse(IdUtil.isOrder('123'));
		Assert.isFalse(IdUtil.isOrder(' '));
		Assert.isFalse(IdUtil.isOrder(''));

		String nullString;
		Assert.isFalse(IdUtil.isOrder(nullString));

		Id nullId;
		Assert.isFalse(IdUtil.isOrder(nullId));
	}

	@isTest
    static void extractId() {
		Account parent = TestDataHelper.insertAccount();
		Account location = TestDataHelper.insertLocation(parent.Id, null);

		Set<Id> extractAllIds = IdUtil.extractId(new Account[]{parent, location});
		Assert.isTrue(extractAllIds.contains(parent.Id));
		Assert.isTrue(extractAllIds.contains(location.Id));

		Set<Id> extractLocationIds = IdUtil.extractId(new Account[]{parent, location}, AccountUtil.RECORDTYPEID_LOCATION);
		Assert.isFalse(extractLocationIds.contains(parent.Id));
		Assert.isTrue(extractLocationIds.contains(location.Id));		
	}
}