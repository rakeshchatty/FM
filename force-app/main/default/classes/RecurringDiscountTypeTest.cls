@IsTest
public with sharing class RecurringDiscountTypeTest {

	@TestSetup
	static void setup() {
		Account parent = TestDataHelper.insertAccount();
		TestDataHelper.insertLocation(parent.Id, null);
		TestDataHelper.insertProduct('CRMFM-7 Test Product', 'CRMFM7-001', 'Collection');
		TestDataHelper.insertSupplier('CRMFM-7 Test Supplier');
	}

	private static Recurrings__c buildRecurring(Id accountId, Id productId, Id supplierId) {
		return new Recurrings__c(
			Account__c = accountId,
			Product__c = productId,
			Supplier__c = supplierId,
			Name = 'CRMFM-7 Test Recurring',
			Type__c = 'Delivery',
			First_Date__c = Date.today().addDays(1),
			Rec__c = 'Month',
			Recur_Every__c = '1'
		);
	}

	private static Id getLocationAccountId() {
		return [SELECT Id FROM Account WHERE RecordType.Name = 'Location' LIMIT 1].Id;
	}

	private static Id getProductId() {
		return [SELECT Id FROM Product2 LIMIT 1].Id;
	}

	private static Id getSupplierId() {
		return [SELECT Id FROM Suppliers__c LIMIT 1].Id;
	}

	@IsTest
	static void should_default_discount_type_to_account_when_both_fields_blank() {
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());

		Test.startTest();
		insert recurring;
		Test.stopTest();

		Recurrings__c saved = [SELECT Discount_to_Apply__c, ManualPrice__c FROM Recurrings__c WHERE Id = :recurring.Id];
		Assert.areEqual('Account', saved.Discount_to_Apply__c, 'Discount_to_Apply__c should default to Account when both it and ManualPrice__c are blank on insert.');
		Assert.isNull(saved.ManualPrice__c, 'ManualPrice__c should remain blank when not explicitly set.');
	}

	@IsTest
	static void should_not_override_explicit_discount_type_when_manual_price_blank() {
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());
		recurring.Discount_to_Apply__c = 'Partner';

		Test.startTest();
		insert recurring;
		Test.stopTest();

		Recurrings__c saved = [SELECT Discount_to_Apply__c FROM Recurrings__c WHERE Id = :recurring.Id];
		Assert.areEqual('Partner', saved.Discount_to_Apply__c, 'An explicitly set Discount_to_Apply__c must not be overridden by the default-assignment flow.');
	}

	@IsTest
	static void should_clear_platform_default_when_manual_price_populated() {
		// Discount_to_Apply__c's picklist metadata marks 'Account' as the default value,
		// which the platform applies to any insert that omits the field - even via Apex/API.
		// The flow must clear that platform-injected default when ManualPrice__c is populated,
		// otherwise the ManualPrice_Requires_Blank_DiscountType validation rule would block
		// every Manual Price save. See specs.md Spec 1 revision note (Gate 6 finding).
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());
		recurring.ManualPrice__c = 50;

		Test.startTest();
		insert recurring;
		Test.stopTest();

		Recurrings__c saved = [SELECT Discount_to_Apply__c, ManualPrice__c FROM Recurrings__c WHERE Id = :recurring.Id];
		Assert.isNull(saved.Discount_to_Apply__c, 'Discount_to_Apply__c must be cleared when ManualPrice__c is populated, even though the platform defaults it to Account by default.');
		Assert.areEqual(50, saved.ManualPrice__c, 'ManualPrice__c should be saved as provided.');
	}

	@IsTest
	static void should_default_discount_type_in_bulk_200_records() {
		Id accountId = getLocationAccountId();
		Id productId = getProductId();
		Id supplierId = getSupplierId();

		List<Recurrings__c> recurrings = new List<Recurrings__c>();
		for (Integer i = 0; i < 200; i++) {
			recurrings.add(buildRecurring(accountId, productId, supplierId));
		}

		Test.startTest();
		insert recurrings;
		Test.stopTest();

		List<Recurrings__c> saved = [SELECT Discount_to_Apply__c FROM Recurrings__c WHERE Id IN :recurrings];
		Assert.areEqual(200, saved.size(), 'All 200 inserted records should be retrievable.');
		for (Recurrings__c rec : saved) {
			Assert.areEqual('Account', rec.Discount_to_Apply__c, 'Every record in a 200-record bulk insert with blank Manual Price and blank Discount Type should default to Account.');
		}
	}

	@IsTest
	static void should_block_save_when_manual_price_and_discount_type_both_populated() {
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());
		recurring.ManualPrice__c = 25;
		recurring.Discount_to_Apply__c = 'Partner';

		DmlException dmlException;
		Test.startTest();
		try {
			insert recurring;
		} catch (DmlException e) {
			dmlException = e;
		}
		Test.stopTest();

		Assert.isNotNull(dmlException, 'Inserting a record with both ManualPrice__c and Discount_to_Apply__c populated should throw a DmlException.');
		Assert.isTrue(
			dmlException.getMessage().contains('Discount Type must be blank when Manual Price is populated.'),
			'The validation error should clearly state that Discount Type must be cleared.'
		);
	}

	@IsTest
	static void should_allow_save_when_manual_price_populated_and_discount_type_blank() {
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());
		recurring.ManualPrice__c = 25;
		recurring.Discount_to_Apply__c = '';

		Test.startTest();
		insert recurring;
		Test.stopTest();

		Recurrings__c saved = [SELECT Id, ManualPrice__c, Discount_to_Apply__c FROM Recurrings__c WHERE Id = :recurring.Id];
		Assert.areEqual(25, saved.ManualPrice__c, 'ManualPrice__c should be saved as provided.');
		Assert.isNull(saved.Discount_to_Apply__c, 'Discount_to_Apply__c should remain blank alongside a populated ManualPrice__c.');
	}

	@IsTest
	static void should_allow_save_when_manual_price_blank_and_discount_type_not_account() {
		// AC5 (blocking this combination) was descoped from CRMFM-7 by explicit developer
		// instruction during Gate 3 - only ManualPrice_Requires_Blank_DiscountType remains.
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());
		recurring.Discount_to_Apply__c = 'Partner';

		Test.startTest();
		insert recurring;
		Test.stopTest();

		Recurrings__c saved = [SELECT Discount_to_Apply__c, ManualPrice__c FROM Recurrings__c WHERE Id = :recurring.Id];
		Assert.areEqual('Partner', saved.Discount_to_Apply__c, 'A blank Manual Price with a non-Account Discount Type must save successfully now that AC5 enforcement is descoped.');
		Assert.isNull(saved.ManualPrice__c, 'ManualPrice__c should remain blank.');
	}

	@IsTest
	static void should_not_reblock_existing_noncompliant_record_on_unrelated_update() {
		Recurrings__c recurring = buildRecurring(getLocationAccountId(), getProductId(), getSupplierId());
		insert recurring;

		Recurrings__c toUpdate = new Recurrings__c(Id = recurring.Id, First_Date__c = Date.today().addDays(2));

		Test.startTest();
		update toUpdate;
		Test.stopTest();

		Recurrings__c saved = [SELECT First_Date__c FROM Recurrings__c WHERE Id = :recurring.Id];
		Assert.areEqual(Date.today().addDays(2), saved.First_Date__c, 'An update that touches neither ManualPrice__c nor Discount_to_Apply__c must not be blocked by the ISCHANGED()-scoped validation rule.');
	}
}
