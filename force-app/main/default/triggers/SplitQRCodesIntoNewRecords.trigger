trigger SplitQRCodesIntoNewRecords on QR_Codes_from_Detrack__c(before insert) {

    List<Qr_code__c> qrCodes = new List<Qr_code__c>();

    for (QR_Codes_from_Detrack__c qr : Trigger.new) {
        if (String.isBlank(qr.QR_Codes_from_OrderItem__c)) {
            continue;
        }

        List<String> codes = qr.QR_Codes_from_OrderItem__c.trim().split('[\n,-]');
        for (String code : codes) {
            qrCodes.add(new Qr_code__c(QR_code_Ref__c = qr.Id, Driver_app_QR_code__c = code, Account__c = qr.Location__c));
        }
        qr.Number_of_codes__c = codes.size();
    }

    if (!qrCodes.isEmpty()) {
        Database.insert(qrCodes, false);
    }
}