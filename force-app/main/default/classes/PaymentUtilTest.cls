@isTest
private class PaymentUtilTest {

	@isTest
	static void transformPaymentMethodCode() {
		Assert.areEqual('DD', PaymentUtil.transformPaymentMethodCode('Direct Debit'));
		Assert.areEqual('Card', PaymentUtil.transformPaymentMethodCode('Credit Card Only'));
		Assert.areEqual('Invoice', PaymentUtil.transformPaymentMethodCode('Invoice'));
		Assert.areEqual('Normal', PaymentUtil.transformPaymentMethodCode('Normal'));
		Assert.areEqual(null, PaymentUtil.transformPaymentMethodCode(''));
		Assert.areEqual(null, PaymentUtil.transformPaymentMethodCode('Invalid'));
	}
}