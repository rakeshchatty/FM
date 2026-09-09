@RestResource(urlMapping='/findcustomerids/*')
global class QRCodeProcessor {
    
    @HttpPost
    global static void findCustomerIdsByQRCodes(List<String> qrCodes) {
        
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        
        String resBody = '[';
        for(String scannedQRCode : qrCodes) {
            
            if (String.isNotBlank(scannedQRCode)) {
                Id customerId = findCustomerIdByQRCode(scannedQRCode);
                if(customerId != null){
                    resBody += '"' + customerId + '",';
                }
            }
        }

        if(resBody.contains(',')){
            
            resBody = resBody.removeEnd(',');
            resBody += ']';

            res.statusCode = 200;
            res.responseBody = Blob.valueOf(resBody);
        }
        else{
            res.statusCode = 200;
            res.responseBody = Blob.valueOf('{"error":"Customer not found!"}');
        }
        
    }

    private static Id findCustomerIdByQRCode(String scannedQRCode) {
        for (Integer i = 0; i < 25; i++) { // try up to 25 attempts
            // Extract the numeric part from the scanned QR code
            String numericPart = scannedQRCode.replaceAll('[^0-9]', '');
            if (String.isNotBlank(numericPart)) {
                Integer numericValue = Integer.valueOf(numericPart) + i; // add i to the numeric value

                // Construct the QR code with the new numeric value
                String incrementedValue = String.valueOf(numericValue);
                String paddedValue = ('000000000' + incrementedValue).substring(incrementedValue.length());
                String firstQRCode = scannedQRCode.replace(numericPart, paddedValue);
                System.debug('Searching for QR code: ' + firstQRCode);

                // Query the custom object to find the customer record
                List<Qr_code__c> qrCodeRecords = [
                    SELECT Account__c
                    FROM Qr_code__c
                    WHERE Driver_app_QR_code__c = :firstQRCode
                    LIMIT 1
                ];

                if (!qrCodeRecords.isEmpty()) {
                    System.debug('Found customer ID ' + qrCodeRecords[0].Account__c + ' for QR code ' + firstQRCode);
                    return qrCodeRecords[0].Account__c;
                } else {
                    System.debug('No results found for QR code ' + firstQRCode);
                }
            }
        }

        return null; // no results found after 25 attempts
    }
}