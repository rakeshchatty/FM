public without sharing class BusinessCentralIntegrationService {

	Map<String, String> endpointMap = new Map<String, String>();

    final Set<Integer> SUCCESS_RESPONSE_CODES = new Set<Integer>{200, 201}; // 200 is for PATCH, 201 is for POST

	public BusinessCentralIntegrationService() {
		endpointMap.put(BusinessCentralRequestChaining.ENTITY_ACCOUNT, 'callout:BusinessCentral/customers');
		endpointMap.put(BusinessCentralRequestChaining.ENTITY_CONTACT, 'callout:BusinessCentral/tecviacontacts');
		endpointMap.put(BusinessCentralRequestChaining.ENTITY_INVOICE, 'callout:BusinessCentral/FMsalesInvoices?$expand=fMsalesInvoiceLines');
		endpointMap.put(BusinessCentralRequestChaining.ENTITY_CREDIT_NOTE, 'callout:BusinessCentral/salesHeaders?$expand=salesLines');
		endpointMap.put(BusinessCentralRequestChaining.ENTITY_PAYMENT, 'callout:BusinessCentral/Payment');
	}

	public static String sendToBusinessCentral(String entityName, String jsonBody, String bcId) {
        BusinessCentralIntegrationService bcService = new BusinessCentralIntegrationService();
        String endpoint = bcService.endpointMap.get(entityName);
		String operationType = String.isBlank(bcId) ? 'POST' : 'PATCH';

        if (operationType == 'PATCH') {
            endpoint += '(\'' + bcId + '\')';
        }
		HttpResponse respose;
		try {
			respose = callout(endpoint, operationType, jsonBody);
			if (bcService.SUCCESS_RESPONSE_CODES.contains(respose.getStatusCode())) {
                Map<String, Object> bcResponse = (Map<String, Object>)JSON.deserializeUntyped(respose.getBody());
                if (entityName == BusinessCentralRequestChaining.ENTITY_ACCOUNT || entityName == BusinessCentralRequestChaining.ENTITY_CONTACT) {
                    bcId = (String) bcResponse.get('Number');
                } else if (entityName == BusinessCentralRequestChaining.ENTITY_PAYMENT) {
					bcId = (String) bcResponse.get('documentNumber');
				} else if (entityName == BusinessCentralRequestChaining.ENTITY_INVOICE || entityName == BusinessCentralRequestChaining.ENTITY_CREDIT_NOTE) {
                    bcId = (String) bcResponse.get('salesforceId');
                }
			} else {
				throw new BusinessCentralException(respose.getBody());
			}
		} catch(Exception e) {
			throw new BusinessCentralException(e.getMessage());
		}

		return bcId;
	}

	public static HttpResponse callout(String endPoint, String method, String body) {
		HttpRequest request = new HttpRequest();
		if (method == 'PATCH') {
			request.setHeader('If-Match', '*');
		}
		request.setEndpoint(endPoint);
		request.setMethod(method);
		request.setTimeout(120000); // 2 min
        if (String.isNotBlank(body)) {
            request.setBody(body);
        }

        HttpResponse response;
        try {
            response = new Http().send(request);
        } catch(Exception e) {
            throw e;
        }

		return response;
	}

	public class BusinessCentralResponse {
		public String id;
	}

	public class BusinessCentralException extends Exception {
	}
}