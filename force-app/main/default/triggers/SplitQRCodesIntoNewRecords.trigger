trigger SplitQRCodesIntoNewRecords on QR_Codes_from_Detrack__c(before insert) {

	List<Qr_code__c> qrCodes = new List<Qr_code__c>();

	for (QR_Codes_from_Detrack__c qr : Trigger.new) {
		if (String.isBlank(qr.QR_Codes_from_OrderItem__c)) {
			qr.Number_of_codes__c = 0;
			continue;
		}

		List<String> codes = qr.QR_Codes_from_OrderItem__c.trim().split('[\n,-]');
		Integer codeCount = 0;
		for (String code : codes) {
			if (String.isBlank(code)) {
				continue;
			}

			qrCodes.add(new Qr_code__c(QR_code_Ref__c = qr.Id, Driver_app_QR_code__c = code.trim().toUpperCase(), Account__c = qr.Location__c, OrderProduct__c = qr.OrderItem__c));
			++codeCount;
		}
		qr.Number_of_codes__c = codeCount;
	}

	if (!qrCodes.isEmpty()) {
		Database.insert(qrCodes, false);
	}
}