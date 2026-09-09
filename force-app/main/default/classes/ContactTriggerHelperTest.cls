@isTest
private class ContactTriggerHelperTest {
	
	@isTest static void test_method_one() {
		Contact c = new Contact();
		c.LastName = 'test c';
		c.Email = 'testemail@email.com';
		insert c;

		try {
			Contact c2 = new Contact();
			c2.LastName = 'test c2';
			c2.Email = 'testemail@email.com';
			insert c2;
		}
		catch (Exception e) {
			system.debug(e.getMessage());
		}
	}
	
	
}