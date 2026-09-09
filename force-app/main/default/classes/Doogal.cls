public class Doogal {

	@future(callout=true)
	public static void retreiveCouncilByPostCode(String postcode, Id accountId) {
		
		Account account = new Account(Id=accountId);
		account.IsCouncilUpdatedViaDoogle__c = false;

		HttpRequest request = new HttpRequest();
		request.setEndpoint('https://www.doogal.co.uk/GetPostcode/' + postcode.replaceAll(' ', ''));
		request.setMethod('GET');
		
		HTTPResponse response = new Http().send(request);
		try {
			account.Council__c = response.getBody().split('\t').get(5);
			account.IsCouncilUpdatedViaDoogle__c = true;
		} catch (Exception e) {
			System.debug(e);
		}

		UPDATE account;
	}
}