public without sharing class PaymentUtil {

	public static String transformPaymentMethodCode(String paymentMethodCode) {
		if (String.isBlank(paymentMethodCode)) {
			return null;
		}

		switch on paymentMethodCode.toUpperCase() {
			WHEN 'DIRECT DEBIT' {
				return 'DD';
			}
			WHEN 'CREDIT CARD ONLY' {
				return 'Card';
			}
			WHEN 'INVOICE' {
				return 'Invoice';
			}
			WHEN 'NORMAL' {
				return 'Normal';
			}
		}
		return null;
	}
}