@RestResource(urlMapping='/DeliveryPackageQrCode/*')
global without sharing class DeliveryPackageQrCodeDuplicateRest {

    @HttpPost
    global static List<String> doPost(List<String> qrCodes) {
        return DeliveryPackageQrCode.verifyDuplicates(qrCodes);
    }
}